#!/bin/bash

#####################################################################################################
# script: Backup incremental oracle database via rman                                               #
# date: 15/02/2016                                                                                  #
# version: 1.3                                                                                      #
# developed by: Rafael Mariotti                                                                     #
# call example: ./backup_database.sh ${SID} ${target_backup_directory} ${flag_send_s3} ${s3_bucket} #
#####################################################################################################

source ~/.bash_profile

check_parameters(){
  echo "checking parameters... (backup_home s3_flag s3_bucket)"
  if [ $# -le 5 ] && [ $# -gt 0 ]; then
    if [ ! -e $2 ]; then
      echo "  ERROR(2): backup home does not exists"
      exit 2
    fi
    if [ "$3" != "send_s3" ] && [ "$3" != "" ]; then
      echo "ERROR(3) wrong s3_flag"
      exit 3
    elif [ "$3" == "send_s3" ] && [ -z `echo "$4" | grep "s3://"` ] && [ -z `echo "$5" | grep "s3://"` ]; then
      echo "ERROR(4): wrong s3_bucket"
      exit 4
    fi
  else
    echo "  ERROR(1): wrong argument number"
    exit 1
  fi

  echo "  Ok."
  return 0
}

delete_old_backups(){
  backup_base=$1
  backup_dir=$2
  s3_archive_backup=$3

  rman target=/ << EOF
    delete noprompt expired backup;
    crosscheck backup;
EOF

  sqlplus -s / as sysdba > /dev/null << EOF
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

  backup_tag=`cat /tmp/backup_tag.log | head -2 | tail -1 | sed 's/^[ \t]*//;s/[ \t]*$//'`

  if [ "${backup_tag}" == "no rows selected" ]; then
    echo "[ ERROR ] There are no available backups to increment."
    exit 1
  fi

  while [ `ps aux | grep "archive_database.sh" | grep -v grep | wc -l` -ne 0 ]
  do
    sleep 60
  done

  date_yesterday=`date +'%Y%m%d' -d "yesterday"`

  rm -rf ${backup_base}/arch${date_yesterday}
  aws s3 rm ${s3_archive_backup}/arch${date_yesterday} --recursive

}

run_backup(){
  backup_home=$1
  backup_date=`date +'%d-%m-%Y'`

  mkdir -p ${backup_home}

  backup_tag=`cat /tmp/backup_tag.log | head -2 | tail -1 | sed 's/^[ \t]*//;s/[ \t]*$//'`
  rm -f /tmp/backup_tag.log

  echo "Starting backup process.. (`date +"%d/%m/%Y %H:%M"`)"
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

  echo "Done (`date +"%d/%m/%Y %H:%M"`)"
}

send_to_s3(){
  backup_home=$1
  s3_flag=$2
  s3_bucket_backup=$3
  backup_dir=$4

  if [ "${s3_flag}" == "send_s3" ]; then
    for file in `ls ${backup_home}`
    do
      if [ `aws s3 ls ${s3_bucket_backup}/${backup_dir}/ | grep ${file} | wc -l` -eq 0 ]
      then
        aws s3 cp ${backup_home}/$file ${s3_bucket_backup}/${backup_dir}/
      fi

      while [ -z `aws s3 ls ${s3_bucket_backup}/${backup_dir}/${file} | awk '{print $4}'` ] || [ `ls -lrt ${backup_home} | grep ${file} | awk '{print $5}'` -ne `aws s3 ls ${s3_bucket_backup}/${backup_dir}/${file} | awk '{print $3}'` ];
      do
        echo "  Currupted file. Sending again..."
        aws s3 cp ${backup_home}/$file ${s3_bucket_backup}/${backup_dir}/
      done
    done
  fi
}

main(){
  backup_dir="diff`date +\"%Y%m%d\"`"
  backup_home=$2/${backup_dir}
  s3_archive_backup=$5

  export ORACLE_SID=$1

  check_parameters $1 $2 $3 $4 $5
  delete_old_backups $2 ${backup_dir} ${s3_archive_backup}
  run_backup ${backup_home}
  send_to_s3 ${backup_home} $3 $4 ${backup_dir}
}

main $1 $2 $3 $4 $5
