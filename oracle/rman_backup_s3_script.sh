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
  BACKUP_BASE=$1
  BACKUP_DIR=$2
  for directory in `ls $BACKUP_BASE | grep "bkp" | grep -v "$BACKUP_DIR"`
  do
    if [ -z `ps aux | grep "s3cmd" | grep "$directory"` ]; then
      echo "  directory $directory deleted"
      rm -rf $BACKUP_BASE/$directory
    fi
    echo ""
  done
}

run_backup(){
  BACKUP_HOME=$1
  mkdir -p $BACKUP_HOME

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
      allocate channel c17 device type disk maxpiecesize 2G;
      allocate channel c18 device type disk maxpiecesize 2G;
      allocate channel c19 device type disk maxpiecesize 2G;
      allocate channel c20 device type disk maxpiecesize 2G;

      delete noprompt expired backup;
      delete noprompt obsolete;
      crosscheck backupset;
      configure snapshot controlfile name to '$BACKUP_HOME/controlfile_%d_backup.ora';
      backup as compressed backupset database format '$BACKUP_HOME/backup_%d_%D%M%Y_dbid_%I_%U.bkp' include current controlfile;

      backup current controlfile for standby format '$BACKUP_HOME/controlfile_standby_%d_backup.ora';
      backup spfile format '$BACKUP_HOME/spfile%d.ora';

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
      release channel c17;
      release channel c18;
      release channel c19;
      release channel c20;
  }
EOF

sqlplus -S / as sysdba << EOF
create pfile='$BACKUP_HOME/pfileprodbr.ora' from spfile;
EOF

  echo "Done (`date +"%d/%m/%Y %H:%M"`)"
}

send_to_s3(){
  BACKUP_HOME=$1
  S3_FLAG=$2
  S3_BUCKET=$3
  BACKUP_DIR=$4

  if [ "$S3_FLAG" == "send_s3" ]; then
    for file in `ls $BACKUP_HOME`; do
      s3cmd put $BACKUP_HOME/$file $S3_BUCKET/$BACKUP_DIR/
      if [ $? -eq 0 ]; then
        if [ `s3cmd ls $S3_BUCKET/$BACKUP_DIR/$file | awk '{print $3}'` ]; then
          echo "  INFO: file $file sent with success to s3 bucket"
        else
          while [ `s3cmd ls $S3_BUCKET/$BACKUP_DIR/$file | grep $file | wc -l` -eq 0 ]; do
            echo "  WARN: file $file is corrupted. Trying to send file again..."
            s3cmd put $BACKUP_HOME/$file $S3_BUCKET/$BACKUP_DIR/
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

  BACKUP_DIR="bkp`date +\"%d%m%Y_%H%M\"`"
  BACKUP_HOME=$1/$BACKUP_DIR

  check_parameters $1 $2 $3
  delete_old_backups $1 $BACKUP_DIR
  run_backup $BACKUP_HOME
  send_to_s3 $BACKUP_HOME $2 $3 $BACKUP_DIR
}

main $1 $2 $3
