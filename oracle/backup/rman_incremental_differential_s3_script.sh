#!/bin/bash

#################################################################################################
# script: Backup incremental oracle database via rman                                           #
# developed by: Rafael Mariotti                                                                 #
#																								#
# arguments: database target_backup_directory parallel_level s3_diff_bucket s3_archive_bucket	#
#################################################################################################

source ~/.bash_profile

function delete_old_backups {
	rman target=/ << EOF
		delete noprompt expired backup;
		crosscheck backup;
EOF

	sqlplus -s / as sysdba << EOF > /dev/null
		set head off;
		spool '/tmp/backup_tag.log';
		SELECT tag
		FROM
			(SELECT tag
			FROM v\$backup_files
			WHERE BACKUP_TYPE = 'BACKUP SET'
			AND FILE_TYPE     = 'PIECE'
			AND BS_TYPE       = 'DATAFILE'
			AND STATUS        = 'AVAILABLE'
			AND TAG LIKE 'BACKUPSET\_%' ESCAPE '\\'
			ORDER BY completion_time DESC nulls last
			) last_tag
		WHERE rownum <=1 ;
		spool off;
EOF

	backup_tag=$(cat /tmp/backup_tag.log | head -2 | tail -1 | sed 's/^[ \t]*//;s/[ \t]*$//')

	if [ "${backup_tag}" == "no rows selected" ]; then
		echo "[ ERROR ] There are no available backups to increment."
		exit 1
	fi

	while [ $(ps aux | grep "archive_database.sh" | grep -v grep | wc -l) -ne 0 ]
	do
		sleep 60
	done

	date_yesterday=$(date +'%Y%m%d' -d "yesterday")

	rm -rf ${backup_base}/arch${date_yesterday}
	aws s3 rm ${s3_backup_archive}/arch${date_yesterday} --recursive

}

function run_backup {
	mkdir -p ${backup_home}

	backup_tag=$(cat /tmp/backup_tag.log | head -2 | tail -1 | sed 's/^[ \t]*//;s/[ \t]*$//')
	rm -f /tmp/backup_tag.log

	echo "Starting backup process.. ($(date +"%d/%m/%Y %H:%M"))"
	backup_date=$(date +'%d-%m-%Y')
	rman target / << EOF
		configure controlfile autobackup off;

		run {
			allocate channel c1 device type disk maxpiecesize 10G;
			allocate channel c2 device type disk maxpiecesize 10G;

			delete noprompt expired backup;
			delete noprompt archivelog all;
			crosscheck backup;
			crosscheck archivelog all;

			backup as compressed backupset incremental level 1 for recover of tag='${backup_tag}' format '${backup_home}/%d_backupset_differential_%s-%p.bkp' database plus archivelog format '${backup_home}/%d_archivelog_%e-%p.bkp' delete input;
			backup tag 'archivelog_${backup_date}' format '${backup_home}/%d_archivelog_%e-%p.bkp' archivelog all delete input;

			backup spfile format '${backup_home}/spfile.bkp';
			backup current controlfile for standby format '${backup_home}/controlfile_stdby.bkp';
			backup current controlfile format '${backup_home}/controlfile.bkp';

			release channel c1;
			release channel c2;
		}
EOF

	sqlplus -S / as sysdba << EOF
		create pfile='${backup_home}/pfile.ora' from spfile;
EOF

	echo "Done ($(date +"%d/%m/%Y %H:%M"))"
}

function send_to_s3 {
	if [ -n "${s3_bucket_diff}" ]; then
		for file in $(ls ${backup_home})
		do
			if [ $(aws s3 ls ${s3_bucket_diff}/${backup_dir}/ | grep ${file} | wc -l) -eq 0 ]
			then
				aws s3 cp ${backup_home}/$file ${s3_bucket_diff}/${backup_dir}/
			fi

			while [ -z $(aws s3 ls ${s3_bucket_diff}/${backup_dir}/${file} | awk '{print $4}') ] || [ $(ls -lrt ${backup_home} | grep ${file} | awk '{print $5}') -ne $(aws s3 ls ${s3_bucket_diff}/${backup_dir}/${file} | awk '{print $3}') ];
			do
				echo "  Currupted file. Sending again..."
				aws s3 cp ${backup_home}/$file ${s3_bucket_diff}/${backup_dir}/
			done
		done
	fi
}

function main {
	database=$1
	backup_base=$2
	parallel_flag=$3
	s3_bucket_diff=$4
	s3_bucket_archive=$5

	backup_dir="diff$(date +\"%Y%m%d\")"
	backup_home=${backup_base}/${backup_dir}

	export ORACLE_SID=${database}

	delete_old_backups
	run_backup
	send_to_s3
}

main $@
