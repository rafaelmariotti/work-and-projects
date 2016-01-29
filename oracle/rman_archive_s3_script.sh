#!/bin/bash

################################################################################################
# script: Backup archive database via rman                                                     #
# date: 12/06/2015                                                                             #
# version: 1.0                                                                                 #
# developed by: Rafael Mariotti                                                                #
# call example: ./archive_database.sh ${target_archive_directory} ${flag_send_s3} ${s3_bucket} #
################################################################################################

source ~/.bash_profile

check_parameters(){
  echo "checking parameters... (archive_home s3_flag s3_bucket)"
  if [ $# -le 3 ] && [ $# -gt 0 ]; then
    if [ ! -e $1 ]; then
      echo "  ERROR(2): archive home does not exists"
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

delete_old_archives(){
  ARCHIVE_BASE=$1
  BACKUP_DIR=$2
  for directory in `ls $ARCHIVE_BASE | grep "arch" | grep -v "$BACKUP_DIR"`
  do
    if [ -z `ps aux | grep "s3cmd" | grep "$directory"` ]; then
      echo "  directory $directory deleted"
      rm -rf $ARCHIVE_BASE/$directory
    fi
    echo ""
  done
}

run_archive(){
  ARCHIVE_HOME=$1
  mkdir -p $ARCHIVE_HOME

  if [ `ps aux | grep archive_database.sh | grep -v "grep" | wc -l` -gt 3 ]; then
    echo "WARNING(1): archive process already running (cant overwrite process)"
    exit
  fi

  echo "Starting archive process... (`date +"%d/%m/%Y %H:%M"`)"
#  rman target sys/0r4SysPwd@dataguard << EOF
  rman target sys/0r4SysPwd << EOF
    run {
      allocate channel c1   device type disk maxpiecesize 2G;
      allocate channel c2   device type disk maxpiecesize 2G;
      allocate channel c3   device type disk maxpiecesize 2G;
      allocate channel c4   device type disk maxpiecesize 2G;
      allocate channel c5   device type disk maxpiecesize 2G;
      allocate channel c6   device type disk maxpiecesize 2G;
      allocate channel c7   device type disk maxpiecesize 2G;
      allocate channel c8   device type disk maxpiecesize 2G;
      allocate channel c9   device type disk maxpiecesize 2G;
      allocate channel c10  device type disk maxpiecesize 2G;

      configure snapshot controlfile name to '$ARCHIVE_HOME/CTL_STBY.bkp' ;
      backup tag 'BACKUP_ARCHIVELOG_BIONEXO' format '$ARCHIVE_HOME/ARCH_%d_%I_%s_%p_%u.BKP' filesperset = 20 archivelog all not backed up;
      delete noprompt archivelog all completed before 'sysdate - 7' backed up 1 times to device type disk;

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
  }
EOF
  echo "Done (`date +"%d/%m/%Y %H:%M"`)"
}

send_to_s3(){
  ARCHIVE_HOME=$1
  S3_FLAG=$2
  S3_BUCKET=$3

  if [ "$S3_FLAG" == "send_s3" ]; then
    for file in `ls $ARCHIVE_HOME`; do
      s3cmd put $ARCHIVE_HOME/$file $S3_BUCKET/$BACKUP_DIR/
      if [ $? -eq 0 ]; then
        if [ `s3cmd ls $S3_BUCKET/$BACKUP_DIR/$file | awk '{print $3}'` ]; then
          echo "  INFO: file $file sent with success to s3 bucket"
          rm -f $ARCHIVE_HOME/$file
        else
          while [ `s3cmd ls $S3_BUCKET/$BACKUP_DIR/$file | grep $file | wc -l` -eq 0 ]; do
            echo "  WARN: file $file is corrupted. Trying to send file again..."
            s3cmd put $ARCHIVE_HOME/$file $S3_BUCKET/$BACKUP_DIR/
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

  BACKUP_DIR="arch`date +\"%d%m%Y\"`"
  ARCHIVE_HOME=$1/$BACKUP_DIR

  check_parameters $1 $2 $3
  delete_old_archives $1 $BACKUP_DIR
  run_archive $ARCHIVE_HOME
  send_to_s3 $ARCHIVE_HOME $2 $3 $BACKUP_DIR
}

main $1 $2 $3
