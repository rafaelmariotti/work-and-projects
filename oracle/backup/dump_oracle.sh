#!/bin/bash

#########################################################################################################
# script: datapump Oracle																				#
# developed by: Rafael Mariotti																			#	
#																										#
# arguments: database dump_home schema_name schema_password schema_name_target parallel_value s3_bucket	#
#########################################################################################################

source ~/.bash_profile

function delete_old_dumps {
	mkdir -p ${dump_home}/${database}/${dump_dir}

	for directory in $(ls ${dump_home}/${database} | grep -v "exp.*" | grep -v "${dump_dir}")
	do
		if [ -z $(ps aux | grep "aws s3" | grep "${dump_home}/${database}/${directory}") ]; then
			echo "  directory ${directory} deleted"
			rm -rf ${dump_home}/${database}/${directory}
		fi
	done
}

function run_dump {
	echo "Starting dump process.. ($(date +"%d/%m/%Y %H:%M"))"
    expdp ${schema_name}/${schema_password}@${database} DIRECTORY=dump_directory DUMPFILE=expDP_${database}_${schema_name_target}.dmp LOGFILE=expDP_${database}_${schema_name_target}.log EXCLUDE=STATISTICS SCHEMAS=${schema_name_target}
	
	gzip -f ${dump_home}/expDP_${database}_${schema_name_target}.dmp
	rm -f ${dump_home}/expDP_${database}_${schema_name_target}.dmp
	mv ${dump_home}/expDP_${database}_${schema_name_target}.dmp.gz ${dump_home}/${database}/${dump_dir}/
	mv ${dump_home}/expDP_${database}_${schema_name_target}.log ${dump_home}/${database}/${dump_dir}/
	echo "Done ($(date +"%d/%m/%Y %H:%M"))"
}

function send_to_s3 {
	if [ -n "${s3_bucket}" ]; then
		aws s3 cp ${dump_home}/${database}/${dump_dir}/expDP_${database}_${schema_name_target}.dmp.gz ${s3_bucket}/${dump_dir}/
		aws s3 cp ${dump_home}/${database}/${dump_dir}/expDP_${database}_${schema_name_target}.log ${s3_bucket}/${dump_dir}/
	fi
}

function main {
	database=$1
	dump_home=$2
	schema_name=$3
	schema_password=$4
	schema_name_target=$5
	parallel_value=$6
	s3_bucket=$7

	dump_dir="dump$(date +\"%d%m%Y\")"
  
	delete_old_dumps
	run_dump
	send_to_s3
}

main $@
