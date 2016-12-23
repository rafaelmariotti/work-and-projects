import sys
from optparse import OptionParser
import cx_Oracle

#ENTRY ARGUMENTS
def arguments():

  parser = OptionParser()
  parser.add_option("-H", "--host", dest="host", help="Database hostname", default="localhost")
  parser.add_option("-s", "--service", dest="service_name", help="service from database")
  parser.add_option("-U", "--username", dest="username", help="Database user to connect")
  parser.add_option("-p", "--password", dest="password", help="Database password to connect")
  parser.add_option("-P", "--port", dest="port", help="Database port listener", default="1521")
  parser.add_option("-l", "--limit", dest="free_space_limit", help="Free space limit to check", default=5)
  (options, args) = parser.parse_args()

  (connection, cursor) = connectOracleOpen(options.host, options.service_name, options.username, options.password, options.port)
  recoverTablespaceInfo(cursor, options.free_space_limit, options.host, options.service_name)
  connectOracleClose(connection, cursor)



#FUNCTION TO OPEN ORACLE CONNECTION
def connectOracleOpen(host, service_name, username, password, port):
  connection_str = username + "/" + password + "@" + host + ":" + port + "/" + service_name

  connection = cx_Oracle.Connection(connection_str)
  cursor     = cx_Oracle.Cursor(connection)

  print("")
  print ("Version    : " + connection.version)
  print ("Encode     : " + connection.encoding)
  print ("Username   : " + connection.username)
  print ("Connection : " + connection.dsn)
  print("")

  return connection, cursor



#FUNCTION TO CLOSE ORACLE CONNECTION
def connectOracleClose(connection, cursor):
  cursor.close()
  connection.close()



#FUNCTION TO RECOVER TABLESPACES INFO
def recoverTablespaceInfo(cursor, free_space_limit, host, service_name):
  free_space_limit=float(free_space_limit)
  print("Recovering tablespaces info...")

  SQL_stmt="""
  SELECT t1.tablespace_name,
    ROUND(t1.maxbytes   /(1024*1024), 2) TOTAL_REAL_MB,
    ROUND((t1.bytes     - t2.freebytes)/(1024*1024), 2) TOTAL_REAL_USED_MB,
    ROUND((t1.maxbytes  - (t1.bytes - t2.freebytes))/(1024*1024), 2) TOTAL_REAL_FREE_MB,
    ROUND(((t1.maxbytes - (t1.bytes - t2.freebytes))*100)/t1.maxbytes, 2) FREE_PERCENTAGE,
    ROUND((t1.bytes)    /(1024*1024), 2) ALLOCATED_OCCUPIED_SIZE_MB
  FROM
    (SELECT tablespace_name,
      SUM(
      CASE
        WHEN maxbytes = 0
        THEN bytes
        ELSE maxbytes
      END ) maxbytes,
      SUM(bytes) bytes
    FROM dba_data_files
    WHERE status='AVAILABLE'
    GROUP BY tablespace_name
    ) t1,
    (SELECT tablespace_name,
      SUM(bytes) freebytes
    FROM dba_free_space
    GROUP BY tablespace_name
    ) t2
  WHERE t1.tablespace_name = t2.tablespace_name
  ORDER BY free_percentage
  """

  cursor.execute(SQL_stmt)
  data_stmt = cursor.fetchall()
  print("Done.")
  print("")
  print("Analyzing tablespaces...")

  for tablespace_info in data_stmt:
    tablespace_name = tablespace_info[0]
    tablespace_free_percent = tablespace_info[4]
    tablespace_free = tablespace_info[3]
    tablespace_size = tablespace_info[1]

    if tablespace_free_percent < free_space_limit :
      print ("  WARNING: Imminent error in host "+ host + ":" + service_name + " with tablespace " + tablespace_name + " [ " + str(tablespace_free_percent) + "% free space - " + str(tablespace_free) + " mb of " + str(tablespace_size) + " mb ]")

  print("Done")
  print("")

if __name__== "__main__":
  argumentStart = arguments
  argumentStart()
