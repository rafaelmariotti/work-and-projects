#!/bin/bash

#################################################################################################
# script: Backup oracle database via rman														#
# developed by: Rafael Mariotti																	#
#																								#
# arguments: database target_backup_directory parallel_level s3_backup_bucket s3_archive_bucket	#
#################################################################################################

source ~/.bash_profile

function delete_old_backups {
	for directory in $(ls ${backup_base} | grep "bkp" | grep -v "${backup_dir}")
	do
		if [ -z $(ps aux | grep "aws s3" | grep "${directory}") ]; then
			echo "  directory ${directory} deleted"
			rm -rf ${backup_base}/${directory}
		fi
		echo ""
	done

	while [ $(ps aux | grep "archive_database.sh" | grep -v grep | wc -l) -ne 0 ]
	do
		sleep 60
	done
	rm -rf ${backup_base}/arch*
	rm -rf ${backup_base}/diff*
}

function run_backup {
	mkdir -p ${backup_home}
	mkdir -p ${archive_home}

	echo "Starting backup process.. ($(date +"%d/%m/%Y %H:%M"))"
	echo "RUNNING" > ${backup_base}/backup_status_${database}.log

	channels=""
    for ((channel_count=1; channel_count <= ${parallel_level}; channel_count++))
    do
      channels=$(echo -e "${channels} allocate channel channel${channel_count} device type disk maxpiecesize 10G;")
    done

	release_channels=""
    for ((channel_count=1; channel_count <= $(cat /proc/cpuinfo | grep processor | wc -l); channel_count++))
    do
      release_channels=$(echo -e "${release_channels} release channel channel${channel_count};")
    done

	rman target=/ << EOF
		configure controlfile autobackup off;

		run {
			${channels}

			delete noprompt expired backup;
			delete noprompt archivelog all;
			crosscheck backup;
			crosscheck archivelog all;

			backup incremental level 0 as compressed backupset database format '${backup_home}/%d_backupset_%s-%p.bkp' tag='backupset_${backup_date}';
			backup as compressed backupset incremental level 1 for recover of tag='backupset_${backup_date}' format '${backup_home}/%d_backupset_differential_%s-%p.bkp' database plus archivelog format '${backup_home}/%d_archivelog_%e-%p.bkp' delete input;
			backup tag 'archivelog_${backup_date}' format '${backup_home}/%d_archivelog_%e-%p.bkp' archivelog all delete input;

			backup spfile format '${backup_home}/spfile.bkp';
			backup current controlfile for standby format '${backup_home}/controlfile_stdby.bkp';
			backup current controlfile format '${backup_home}/controlfile.bkp';

			${release_channels}
  }
EOF
	sqlplus -S / as sysdba << EOF
		create pfile='${backup_home}/pfile.ora' from spfile;
EOF

	echo "DONE" > ${backup_base}/backup_status_${database}.log
	echo "Done ($(date +"%d/%m/%Y %H:%M"))"
}

function send_to_s3 {
	if [ -n "${s3_bucket_backup}" ]; then
		for file in $(ls ${archive_home})
		do
			if [ $(aws s3 ls ${s3_bucket_archive}/${archive_dir}/ | grep ${file} | wc -l) -eq 0 ]
			then
				aws s3 cp ${archive_home}/${file} ${s3_bucket_archive}/${archive_dir}/${file}
			fi

			while [ -z $(aws s3 ls ${s3_bucket_archive}/${archive_dir}/${file} | awk '{print $4}') ] || [ $(ls -lrt ${archive_home} | grep ${file} | awk '{print $5}') -ne $(aws s3 ls ${s3_bucket_archive}/${archive_dir}/${file} | awk '{print $3}') ];
			do
				echo "  Currupted file. Sending again..."
				aws s3 cp ${archive_home}/${file} ${s3_bucket_archive}/${archive_dir}/${file}
			done
		done

		for file in $(ls ${backup_home})
		do
			if [ $(aws s3 ls ${s3_bucket_backup}/${backup_dir}/ | grep ${file} | wc -l) -eq 0 ]
			then
				aws s3 cp ${backup_home}/$file ${s3_bucket_backup}/${backup_dir}/
			fi

			while [ -z $(aws s3 ls ${s3_bucket_backup}/${backup_dir}/${file} | awk '{print $4}') ] || [ $(ls -lrt ${backup_home} | grep ${file} | awk '{print $5}') -ne $(aws s3 ls ${s3_bucket_backup}/${backup_dir}/${file} | awk '{print $3}') ];
			do
				echo "  Currupted file. Sending again..."
				aws s3 cp ${backup_home}/$file ${s3_bucket_backup}/${backup_dir}/
			done
		done
	fi
}

function main {
	database=$1
	backup_base=$2
	parallel_level=$3
	s3_bucket_backup=$4
	s3_bucket_archive=$5

	backup_dir="bkp$(date +\"%Y%m%d_%H%M\")"
	backup_home=${backup_base}/${backup_dir}

	archive_dir="arch$(date +\"%Y%m%d\")"
	archive_home=${backup_base}/${archive_dir}

	export ORACLE_SID=${database}

	delete_old_backups
	run_backup
	send_to_s3
}

main $@
