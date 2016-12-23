#!/bin/bash

#####################################################################################################################################################################################
# script: datapump on Oracle Amazon RDS																																				#
# developed by: Rafael Mariotti																																						#
#																																													#
# arguments: database dump_home schema_name schema_password dest_hostname dest_port dest_service_name schema_name_target schema_password_target schema_name_target_dump s3_bucket	#
#####################################################################################################################################################################################

source ~/.bash_profile

function delete_old_dumps {
	mkdir -p ${dump_home}/${database}/${dump_dir}

	for directory in $(ls ${dump_home}/${database} | grep -v "exp.*" | grep -v "${dump_dir}")
	do
		if [ -z "$(ps aux | grep "aws s3" | grep "${dump_home}/${database}/${directory}")" ]; then
			echo "  directory ${directory} deleted"
			rm -rf ${dump_home}/${database}/${directory}
		fi
	done
}

function run_dump {
	echo "Starting dump process.. ($(date +"%d/%m/%Y %H:%M"))"
	expdp ${schema_name_target}/${schema_password_target}@${database} DIRECTORY=data_pump_dir DUMPFILE=expDP_${database}_${schema_name_target_dump}.dmp LOGFILE=expDP_${database}_${schema_name_target_dump}.log EXCLUDE=STATISTICS SCHEMAS=${schema_name_dump}

	sqlplus ${schema_name_target}/${schema_password_target}@${database} << EOF
		drop database link DUMP_TARGET;
		create database link DUMP_TARGET connect to ${schema_name} identified by "${schema_password}" using '(DESCRIPTION = (ADDRESS = (PROTOCOL = TCP)(HOST = ${dest_hostname})(PORT = ${dest_port})) (CONNECT_DATA = (SERVER = DEDICATED) (SERVICE_NAME = ${dest_service_name})))';

		BEGIN
		DBMS_FILE_TRANSFER.PUT_FILE(
			source_directory_object       => 'DATA_PUMP_DIR',
			source_file_name              => 'expDP_${database}_${schema_name_target_dump}.dmp',
			destination_directory_object  => 'DUMP_DIRECTORY',
			destination_file_name         => 'expDP_${database}_${schema_name_target_dump}.dmp',
			destination_database          => 'DUMP_TARGET'
		);
    
		UTL_FILE.FREMOVE(
			location => 'DATA_PUMP_DIR',
			filename => 'expDP_${database}_${schema_name_target_dump}.dmp'
		);

		UTL_FILE.FREMOVE(
			location => 'DATA_PUMP_DIR',
			filename => 'expDP_${database}_${schema_name_target_dump}.log'
		);
		END;
		/
EOF

	gzip -f ${dump_home}/expDP_${database}_${schema_name_target_dump}.dmp
	mv ${dump_home}/expDP_${database}_${schema_name_target_dump}.dmp.gz ${dump_home}/${database}/${dump_dir}/
	echo "Done ($(date +"%d/%m/%Y %H:%M"))"
}

function send_to_s3 {
	if [ -n "${s3_bucket}" ]; then
		aws s3 cp ${dump_home}/${database}/${dump_dir}/expDP_${database}_${schema_name_target_dump}.dmp.gz ${s3_bucket}/${dump_dir}/
		rm -f ${dump_home}/expDP_${database}_${schema_name_target_dump}.dmp.gz
	fi
}

function main {
	database=$1
	dump_home=$2
	schema_name=$3
	schema_password=$4
	dest_hostname=$5
	dest_port=$6
    dest_service_name=$7
	schema_name_target=$8
	schema_password_target=$9
	schema_name_target_dump=${10}
	s3_bucket=${11}

	dump_dir="dump$(date +\"%d%m%Y\")"

	delete_old_dumps
	run_dump
	send_to_s3
}

main $@
