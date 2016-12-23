#!/bin/bash

#########################################################################
# script: Backup postgres database										#
# developed by: Rafael Mariotti											#
#																		#
# arguments: hostname database username password dump_home s3_bucket	#
#########################################################################

source ~/.bash_profile

function delete_old_dumps {
	mkdir -p ${dump_home}/${database}/${dump_dir}

	for directory in $(ls ${dump_home}/${database} | grep -v "*.dmp" | grep -v "${dump_dir}") 
	do
		if [ -z $(ps aux | grep "aws s3" | grep "${dump_home}/${database}/${directory}") ]; then
		echo "  directory ${directory} deleted"
		rm -rf ${dump_home}/${database}/${directory}
		fi
	done
}

function run_dump {
	echo "Starting dump process.. ($(date +"%d/%m/%Y %H:%M"))"

	export PGPASSWORD="${password}"
	pg_dumpall -h ${hostname} -U ${username} -f ${dump_home}/${database}/${dump_dir}/${database}.dmp > /tmp/pg_dump_${database}.log

	if [ $(wc -l /tmp/pg_dump_${database}.log | awk '{print $1}') -gt 0 ]; then
		echo "Something went wrong with pg_dump, sending email..."
		echo "Please check logfile attached for more details." > /tmp/mail_body.txt 
		mail -r report@bionexo.com -s "pg_dumpall ${database} - error [$(date +"%d/%m/%Y %H:%M")]" -a /tmp/pg_dump_${database}.log dba@bionexo.com < /tmp/mail_body.txt
		rm -f /tmp/mail_body.txt
	else
		gzip -f ${dump_home}/${database}/${dump_dir}/${database}.dmp
		rm -f ${dump_home}/${database}/${dump_dir}/${database}.dmp
		echo "Done ($(date +"%d/%m/%Y %H:%M"))"
	fi
}

function send_to_s3 {
	if [ -n "${s3_bucket}" ]; then
		aws s3 cp ${dump_home}/${database}/${dump_dir}/${database}.dmp.gz ${s3_bucket}/${dump_dir}/
		rm -f ${dump_home}/${database}/${dump_dir}/${database}.dmp.gz
	fi
}

function main {
	hostname=$1
	database=$2
	username=$3
	password=$4
	dump_home=$5
	s3_bucket=$6

	dump_dir="dump$(date +\"%Y%m%d\")"
  
	delete_old_dumps
	run_dump 
	send_to_s3
}

main $@
