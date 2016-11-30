BEGIN
  DBMS_FILE_TRANSFER.PUT_FILE(
    source_directory_object       => 'DATAPUMP',
    source_file_name              => 'dump_all.dmp',
    destination_directory_object  => 'DATA_PUMP_DIR',
    destination_file_name         => 'dump_all.dmp', 
    destination_database          => 'db_link'
  );
END;
/ 

--display all files from directory using AWS RDS
select * from table(RDSADMIN.RDS_FILE_UTIL.LISTDIR('DATA_PUMP_DIR')) order by mtime;  

BEGIN
  UTL_FILE.FREMOVE (
    location => 'DATAPUMP',
    filename => 'dump_all.dmp'
  );
END;
/
