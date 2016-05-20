#!/bin/bash

############################################
# script: Backup archive database via rman #
# date: 12/06/2015                         #
# version: 1.0                             #
# developed by: Rafael Mariotti            #
############################################

source ~/.bash_profile

check_parameters(){
  echo "checking parameters... (archive_home s3_flag s3_bucket)"
  if [ $# -le 4 ] && [ $# -gt 0 ]; then
    if [ ! -e $2 ]; then
      echo "  ERROR(2): archive home does not exists"
      exit 2
    fi
    if [ "$3" != "send_s3" ] && [ "$3" != "" ]; then
      echo "ERROR(3) wrong s3_flag"
      exit 3
    elif [ "$3" == "send_s3" ] && [ -z `echo "$4" | grep "s3://"` ]; then
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

delete_old_archives(){
  archive_base=$1
  backup_dir=$2

  find ${archive_base}/* -type d -ctime +7 -exec rm -rf {} \;
}

run_archive(){
  archive_home=$1

  mkdir -p ${archive_home}
  if [ `ps aux | grep archive_database.sh | grep -v "grep" | wc -l` -gt 3 ]; then
    echo "WARNING(1): archive process already running (cant overwrite process)"
    exit
  fi

  echo "Starting archive process... (`date +"%d/%m/%Y %H:%M"`)"
  archive_hour=`date +"%m-%d-%Y_%H:%M"`

  rm -f ${archive_home}/controlfile.bkp
  rman target sys/0r4SysPwd << EOF
    run {
      configure controlfile autobackup off;

      allocate channel c1 device type disk maxpiecesize 2G;
      allocate channel c2 device type disk maxpiecesize 2G;

      backup tag 'archivelog_${archive_hour}' format '${archive_home}/%d_archivelog_%s-%p.bkp' archivelog all delete input;
      backup current controlfile format '${archive_home}/controlfile.bkp';

      release channel c1;
      release channel c2;
  }
EOF
  echo "Done (`date +"%d/%m/%Y %H:%M"`)"
}

send_to_s3(){
  archive_home=$1
  s3_flag=$2
  s3_bucket_archive=$3
  archive_dir=$4

  s3cmd del ${s3_bucket}/${backup_dir}/controlfile.bkp

  if [ "${s3_flag}" == "send_s3" ]; then
    for file in `ls ${archive_home}`
    do
      if [ `s3cmd ls ${s3_bucket_archive}/${archive_dir}/ | grep ${file} | wc -l` -eq 0 ]
      then
        s3cmd put ${archive_home}/${file} ${s3_bucket_archive}/${archive_dir}/${file}
      fi

      while [ -z `s3cmd ls ${s3_bucket_archive}/${archive_dir}/${file} | awk '{print $4}'` ] || [ `ls -lrt ${archive_home} | grep ${file} | awk '{print $5}'` -ne `s3cmd du ${s3_bucket_archive}/${archive_dir}/${file} | awk '{print $1}'` ];
      do
        echo "  Currupted file. Sending again..."
        s3cmd put ${archive_home}/${file} ${s3_bucket_archive}/${archive_dir}/${file}
      done
    done
  fi
}

main(){
  archive_base=$2
  s3_flag=$3
  s3_bucket=$4
  backup_dir="arch`date +\"%Y%m%d\"`"
  archive_home=${archive_base}/${backup_dir}

  export ORACLE_SID=$1

  check_parameters $1 $2 $3 $4
  delete_old_archives $2 ${backup_dir}
  run_archive ${archive_home}
  send_to_s3 ${archive_home} ${s3_flag} ${s3_bucket} ${backup_dir}
}

main $1 $2 $3 $4
