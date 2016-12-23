#!/bin/bash

#####################################################################
# script: statistic system Oracle									#
# developed by: Rafael Mariotti										#
#																	#
# arguments: database schema_name schema_password parallel_level	#
#####################################################################

source ~/.bash_profile

function run_statistic {
	echo "Starting statistic process.. ($(date +"%d/%m/%Y %H:%M"))"

	sqlplus ${schema_name}/${schema_password}@${database} <<EOF
		exec dbms_stats.GATHER_DICTIONARY_STATS(cascade => true, method_opt => 'for all columns size skewonly', degree => ${parallel_value});
EOF
  echo "Done ($(date +"%d/%m/%Y %H:%M"))"
}

function main {
	database=$1
	schema_name=$2
	schema_password=$3
	parallel_level=$4

  run_statistic
}

main $@
