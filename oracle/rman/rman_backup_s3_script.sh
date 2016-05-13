#!/bin/bash

##############################################################################################
# script: Backup oracle database via rman                                                    #
# date: 15/02/2016                                                                           #
# version: 1.3                                                                               #
# developed by: Rafael Mariotti                                                              #
# call example: ./backup_database.sh ${target_backup_directory} ${flag_send_s3} ${s3_bucket} #
##############################################################################################

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
  for directory in `ls ${backup_base} | grep "bkp" | grep -v "${backup_dir}"`
  do
    if [ -z `ps aux | grep "s3cmd" | grep "${directory}"` ]; then
      echo "  directory ${directory} deleted"
      rm -rf ${backup_base}/${directory}
    fi
    echo ""
  done

  while [ `ps aux | grep "archive_database.sh" | grep -v grep | wc -l` -ne 0 ]
  do
    sleep 60
  done
  rm -rf ${backup_base}/arch*
  rm -rf ${backup_base}/diff*

}

run_backup(){
  backup_home=$1
  archive_home=$2
  backup_date=`date +'%d-%m-%Y'`
  archive_hour=`date +"%m-%d-%Y_%H:%M"`

  mkdir -p ${backup_home}
  mkdir -p ${archive_home}

  echo "Starting backup process.. (`date +"%d/%m/%Y %H:%M"`)"
  rman target / << EOF
    configure controlfile autobackup off;

    run {
      allocate channel c1  device type disk maxpiecesize 10G;
      allocate channel c2  device type disk maxpiecesize 10G;
      allocate channel c3  device type disk maxpiecesize 10G;
      allocate channel c4  device type disk maxpiecesize 10G;
      allocate channel c5  device type disk maxpiecesize 10G;
      allocate channel c6  device type disk maxpiecesize 10G;
      allocate channel c7  device type disk maxpiecesize 10G;
      allocate channel c8  device type disk maxpiecesize 10G;
      allocate channel c9  device type disk maxpiecesize 10G;
      allocate channel c10 device type disk maxpiecesize 10G;
      allocate channel c11 device type disk maxpiecesize 10G;
      allocate channel c12 device type disk maxpiecesize 10G;
      allocate channel c13 device type disk maxpiecesize 10G;
      allocate channel c14 device type disk maxpiecesize 10G;
      allocate channel c15 device type disk maxpiecesize 10G;
      allocate channel c16 device type disk maxpiecesize 10G;

      delete noprompt expired backup;
      delete noprompt archivelog all;
      crosscheck backup;
      crosscheck archivelog all;

      backup incremental level 0 as compressed backupset database format '${backup_home}/%d_backupset_%s-%p.bkp' tag='backupset_${backup_date}' plus archivelog format '${backup_home}/%d_archivelog_%e-%p.bkp' tag='archivelog_${backup_date}' delete input;
      backup tag 'archivelog_${backup_date}' format '${backup_home}/%d_archivelog_%e-%p.bkp' archivelog all delete input;

      backup spfile format '${backup_home}/spfile.bkp';
      backup current controlfile for standby format '${backup_home}/controlfile_stdby.bkp';
      backup current controlfile format '${backup_home}/controlfile.bkp';

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
  create pfile='${backup_home}/pfile.ora' from spfile;
EOF

  echo "Done (`date +"%d/%m/%Y %H:%M"`)"
}

send_to_s3(){
  backup_home=$1
  archive_home=$2
  s3_flag=$3
  s3_bucket_backup=$4
  s3_bucket_archive=$5
  backup_dir=$6
  archive_dir=$7

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

    for file in `ls ${backup_home}`
    do
      if [ `s3cmd ls ${s3_bucket_backup}/${backup_dir}/ | grep ${file} | wc -l` -eq 0 ]
      then
        s3cmd put ${backup_home}/$file ${s3_bucket_backup}/${backup_dir}/
      fi

      while [ -z `s3cmd ls ${s3_bucket_backup}/${backup_dir}/${file} | awk '{print $4}'` ] || [ `ls -lrt ${backup_home} | grep ${file} | awk '{print $5}'` -ne `s3cmd du ${s3_bucket_backup}/${backup_dir}/${file} | awk '{print $1}'` ];
      do
        echo "  Currupted file. Sending again..."
        s3cmd put ${backup_home}/$file ${s3_bucket_backup}/${backup_dir}/
      done
    done
  fi
}

main(){
  backup_dir="bkp`date +\"%Y%m%d_%H%M\"`"
  backup_home=$2/${backup_dir}
  archive_dir="arch`date +\"%Y%m%d\"`"
  archive_home=$2/${archive_dir}

  export ORACLE_SID=$1

#  check_parameters $1 $2 $3 $4 $5
#  delete_old_backups $2 ${backup_dir}
  run_backup ${backup_home} ${archive_home}
#  send_to_s3 ${backup_home} ${archive_home} $3 $4 $5 ${backup_dir} ${archive_dir}
}

main $1 $2 $3 $4 $5
