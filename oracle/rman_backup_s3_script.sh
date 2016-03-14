#!/bin/bash

##############################################################################################
# script: Backup oracle database via rman                                                    #
# date: 31/08/2015                                                                           #
# version: 1.2                                                                               #
# developed by: Rafael Mariotti                                                              #
# call example: ./backup_database.sh ${target_backup_directory} ${flag_send_s3} ${s3_bucket} #
##############################################################################################

source ~/.bash_profile

check_parameters(){
  echo "checking parameters... (backup_home s3_flag s3_bucket)"
  if [ $# -le 3 ] && [ $# -gt 0 ]; then
    if [ ! -e $1 ]; then
      echo "  ERROR(2): backup home does not exists"
      exit 2
    fi
    if [ "$2" != "send_s3" ] && [ "$2" != "" ]; then
      echo "ERROR(3) wrong s3_flag"
      exit 3
    elif [ "$2" == "send_s3" ] && [ -z `echo "$3" | grep "s3://"` ]; then
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
  for directory in `ls ${backup_base} | grep "bkp" | grep -v "${backup_dir}"`
  do
    if [ -z `ps aux | grep "s3cmd" | grep "${directory}"` ]; then
      echo "  directory ${directory} deleted"
      rm -rf ${backup_base}/${directory}
    fi
    echo ""
  done
}

run_backup(){
  backup_home=$1
  backup_date=`date +'%d%m%Y'`
  mkdir -p ${backup_home}

  echo "Starting backup process.. (`date +"%d/%m/%Y %H:%M"`)"
  rman target / << EOF
    configure controlfile autobackup off;
    run {
      allocate channel c1  device type disk maxpiecesize 2G;
      allocate channel c2  device type disk maxpiecesize 2G;
      allocate channel c3  device type disk maxpiecesize 2G;
      allocate channel c4  device type disk maxpiecesize 2G;
      allocate channel c5  device type disk maxpiecesize 2G;
      allocate channel c6  device type disk maxpiecesize 2G;
      allocate channel c7  device type disk maxpiecesize 2G;
      allocate channel c8  device type disk maxpiecesize 2G;
      allocate channel c9  device type disk maxpiecesize 2G;
      allocate channel c10 device type disk maxpiecesize 2G;
      allocate channel c11 device type disk maxpiecesize 2G;
      allocate channel c12 device type disk maxpiecesize 2G;
      allocate channel c13 device type disk maxpiecesize 2G;
      allocate channel c14 device type disk maxpiecesize 2G;
      allocate channel c15 device type disk maxpiecesize 2G;
      allocate channel c16 device type disk maxpiecesize 2G;

      delete noprompt expired backup;
      crosscheck backup;

      backup incremental level 0 as compressed backupset database format '${backup_home}/%d_backupset_%s-%p.bkp' tag='backupset_${backup_date}' plus archivelog format '${backup_home}/%d_archivelog_%e_%p.bkp' tag='archivelog_${backup_date}' not backed up;

      backup current controlfile format '${backup_home}/controlfile.bkp';
      backup current controlfile for standby format '${backup_home}/controlfile_stdby.bkp';
      backup spfile format '${backup_home}/spfile.bkp';

      release channel c1;
      release channel c2;
      release channel c3;
      release channel c4;
      release channel c5;
      release channel c6;
      release channel c7;
      release channel c8;
      release channel c9;
      release channel c10;
      release channel c11;
      release channel c12;
      release channel c13;
      release channel c14;
      release channel c15;
      release channel c16;
  }
EOF

sqlplus -S / as sysdba << EOF
create pfile='${backup_home}/pfileprodbr.ora' from spfile;
EOF

  echo "Done (`date +"%d/%m/%Y %H:%M"`)"
}

send_to_s3(){
  backup_home=$1
  s3_flag=$2
  s3_bucket=$3
  backup_dir=$4

  if [ "${s3_flag}" == "send_s3" ]; then
    for file in `ls ${backup_home}`; do
      s3cmd put ${backup_home}/$file ${s3_bucket}/${backup_dir}/
      if [ $? -eq 0 ]; then
        if [ `s3cmd ls ${s3_bucket}/${backup_dir}/$file | awk '{print $3}'` ]; then
          echo "  INFO: file $file sent with success to s3 bucket"
        else
          while [ `s3cmd ls ${s3_bucket}/${backup_dir}/$file | grep $file | wc -l` -eq 0 ]; do
            echo "  WARN: file $file is corrupted. Trying to send file again..."
            s3cmd put ${backup_home}/$file ${s3_bucket}/${backup_dir}/
          done
          echo "  INFO: file $file sent with success to s3 bucket"
        fi
      fi
    done
  else
    echo "  Warning: S3 flag was not set"
  fi
}

main(){

  backup_dir="bkp`date +\"%d%m%Y_%H%M\"`"
  backup_home=$1/${backup_dir}

  check_parameters $1 $2 $3
  delete_old_backups $1 ${backup_dir}
  run_backup ${backup_home}
  send_to_s3 ${backup_home} $2 $3 ${backup_dir}
}

main $1 $2 $3
