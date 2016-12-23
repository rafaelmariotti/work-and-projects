#!/bin/bash

#################################################################################
# script: Backup archive database via rman										#
# developed by: Rafael Mariotti													#
#																				#
# arguments: database target_archive_directory parallel_level s3_archive_bucket	#
#################################################################################

source ~/.bash_profile

function delete_old_archives {
	find ${archive_base}/* -type d -ctime +7 -exec rm -rf {} \;
}

function run_archive {
	mkdir -p ${archive_home}
	if [ $(ps aux | grep archive_database.sh | grep -v "grep" | wc -l) -gt 3 ]; then
		echo "WARNING(1): archive process already running (cant overwrite process)"
		exit
	fi

	echo "Starting archive process... ($(date +"%d/%m/%Y %H:%M"))"
	echo "RUNNING" > ${backup_base}/archive_status_${database}.log
	archive_hour=$(date +"%m-%d-%Y_%H:%M")

	channels=""
    for ((channel_count=1; channel_count <= ${parallel_level}; channel_count++))
    do
      channels=$(echo -e "${channels} allocate channel channel${channel_count} device type disk maxpiecesize 2G;")
    done

    release_channels=""
    for ((channel_count=1; channel_count <= $(cat /proc/cpuinfo | grep processor | wc -l); channel_count++))
    do
      release_channels=$(echo -e "${release_channels} release channel channel${channel_count};")
    done

	rm -f ${archive_home}/controlfile.bkp
	rman target sys/0r4SysPwd << EOF
		run {
			configure controlfile autobackup off;

			${channels}

			backup tag 'archivelog_${archive_hour}' format '${archive_home}/%d_archivelog_%s-%p.bkp' archivelog all delete input;
			backup current controlfile format '${archive_home}/controlfile.bkp';

			${release_channels}
  }
EOF
	echo "DONE" > ${backup_base}/archive_status_${database}.log
	echo "Done ($(date +"%d/%m/%Y %H:%M"))"
}

function send_to_s3 {
  aws s3 rm ${s3_bucket}/${backup_dir}/controlfile.bkp --quiet

	if [ -n "${s3_bucket}" ]; then
		for file in $(ls ${archive_home})
		do
			if [ $(aws s3 ls ${s3_bucket_archive}/${archive_dir}/ | grep ${file} | wc -l) -eq 0 ]
			then
				aws s3 cp ${archive_home}/${file} ${s3_bucket_archive}/${archive_dir}/${file} #--multipart-chunk-size-mb=512
			fi

			while [ -z $(aws s3 ls ${s3_bucket_archive}/${archive_dir}/${file} | awk '{print $4}') ] || [ $(ls -lrt ${archive_home} | grep ${file} | awk '{print $5}') -ne $(aws s3 ls ${s3_bucket_archive}/${archive_dir}/${file} | awk '{print $3}') ];
			do
				echo "  Currupted file. Sending again..."
				aws cp ${archive_home}/${file} ${s3_bucket_archive}/${archive_dir}/${file} #--multipart-chunk-size-mb=512
			done
		done
	fi
}

function main {
	database=$1
	archive_base=$2
	parallel_level=$3
	s3_bucket=$4
	backup_dir="arch$(date +\"%Y%m%d\")"
	archive_home=${archive_base}/${backup_dir}

	export ORACLE_SID=${database}

	delete_old_archives
	run_archive
	send_to_s3
}

main $@
