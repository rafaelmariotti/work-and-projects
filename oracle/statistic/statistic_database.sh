#!/bin/bash

#####################################################################
# script: Statistics Oracle database								#
# developed by: Rafael Mariotti										#
#																	#
# arguments: database schema_user schema_password percent degree	#
#####################################################################

source ~/.bash_profile

function run_statistic {
	echo "Starting statistic process.. ($(date +"%d/%m/%Y %H:%M"))"

	sqlplus -S ${schema_user}/${schema_password}@${database} <<EOF
SET serveroutput ON;
DECLARE
BEGIN
  FOR object_info IN
  (SELECT dt.owner,
    dt.table_name
  FROM dba_tables dt
  WHERE TEMPORARY                = 'N'
  AND (dt.iot_type               IS NULL
  OR dt.iot_type                 != 'IOT_OVERFLOW')
  AND NOT EXISTS
    (SELECT 1
    FROM dba_external_tables det
    WHERE det.owner   = dt.owner
    AND det.table_name=dt.table_name
    )
  AND EXISTS
    (SELECT 1
    FROM DBA_TAB_STATISTICS dts
    WHERE dts.owner      =dt.owner
    AND dts.table_name   =dt.table_name
    AND stattype_locked IS NULL
    )
  ORDER BY dt.owner,
    dt.table_name
  )
  LOOP
    BEGIN
      dbms_stats.gather_table_stats(ownname=> '"' || object_info.owner || '"', tabname=> '"' || object_info.table_name || '"', CASCADE=> true, method_opt => 'for all columns size skewonly', estimate_percent=>${percent}, degree => ${degree});
      dbms_output.put_line('(success) statistic from ' || lower(object_info.owner || '.' || object_info.table_name));
    EXCEPTION
    WHEN OTHERS THEN
      dbms_output.put_line('error calculating statistic from ' || object_info.owner ||'.' || object_info.table_name || ': ' || sqlerrm);
    END;
  END LOOP;
END;
/
EOF
  echo "Done ($(date +"%d/%m/%Y %H:%M"))"
}

function main {
	database=$1
	schema_user=$2
	schema_password=$3
	percent=$4
	degree=$5

	run_statistic
}

main $@
