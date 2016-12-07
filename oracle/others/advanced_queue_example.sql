----
--@as sysdba
----
CREATE USER admin_aq IDENTIFIED BY "admin_aq";
ALTER USER admin_aq DEFAULT TABLESPACE tablespace_default;
GRANT unlimited TABLESPACE TO admin_aq;
GRANT CONNECT, RESOURCE TO admin_aq;
GRANT EXECUTE ON sys.dbms_aqadm TO admin_aq;

CREATE USER user_aq IDENTIFIED BY "user_aq";
ALTER USER user_aq DEFAULT TABLESPACE tablespace_default;
GRANT unlimited TABLESPACE TO user_aq;
GRANT CONNECT, RESOURCE TO user_aq;

GRANT SELECT ON user.first_table TO user_aq;
GRANT SELECT ON user.second_table TO user_aq;


----
--@admin_aq
----

CREATE OR REPLACE TYPE type_first_table_aq
IS
  OBJECT
  (
	id_tablee		NUMBER,
	login			varchar2(30),
	info			varchar2(100)
  );
/

CREATE OR REPLACE TYPE type_second_table_aq
IS
  OBJECT
  (
    id_tablee       NUMBER,
    login           varchar2(30),
    info            varchar2(100)
  );
/

EXECUTE dbms_aqadm.create_queue_table(queue_table => 'tb_first_table_aq', queue_payload_type => 'type_first_table_aq', multiple_consumers => TRUE, COMMENT => 'Messages from table user.first_table');
EXECUTE dbms_aqadm.create_queue_table(queue_table => 'tb_second_table_aq', queue_payload_type => 'type_second_table_aq', multiple_consumers => TRUE, COMMENT => 'Messages from table user.second_table');

EXECUTE dbms_aqadm.create_queue(queue_name => 'q_first_table_aq', queue_table => 'tb_first_table_aq');
EXECUTE dbms_aqadm.create_queue(queue_name => 'q_second_table_aq', queue_table => 'tb_second_table_aq');

EXECUTE dbms_aqadm.create_queue(queue_name => 'q_first_except', queue_table => 'tb_first_table_aq', queue_type => dbms_aqadm.EXCEPTION_QUEUE);
EXECUTE dbms_aqadm.create_queue(queue_name => 'q_second_except', queue_table => 'tb_second_table_aq', queue_type => dbms_aqadm.EXCEPTION_QUEUE);

EXECUTE dbms_aqadm.start_queue(queue_name => 'q_first_table_aq');
EXECUTE dbms_aqadm.start_queue(queue_name => 'q_second_table_aq');

EXECUTE dbms_aqadm.start_queue(queue_name => 'q_first_except', enqueue => FALSE);
EXECUTE dbms_aqadm.start_queue(queue_name => 'q_second_except', enqueue => FALSE);

DECLARE
  subscriber1 sys.aq$_agent := sys.aq$_agent('consumer_first_table1', NULL, NULL);
  subscriber2 sys.aq$_agent := sys.aq$_agent('consumer_first_table2', NULL, NULL);
BEGIN
  dbms_aqadm.add_subscriber(queue_name => 'q_first_table_aq', subscriber => subscriber1);
  dbms_aqadm.add_subscriber(queue_name => 'q_first_table_aq', subscriber => subscriber2);
END;
/

DECLARE
  subscriber1 sys.aq$_agent := sys.aq$_agent('consumer_second_table1', NULL, NULL);
  subscriber2 sys.aq$_agent := sys.aq$_agent('consumer_second_table2', NULL, NULL);
BEGIN
  dbms_aqadm.add_subscriber(queue_name => 'q_second_table_aq', subscriber => subscriber1);
  dbms_aqadm.add_subscriber(queue_name => 'q_second_table_aq', subscriber => subscriber2);
END;
/

GRANT EXECUTE ON admin_aq.type_first_table_aq TO user_aq;
GRANT EXECUTE ON admin_aq.type_second_table_aq TO user_aq;

BEGIN
  dbms_aqadm.grant_queue_privilege ( privilege => 'ALL', queue_name => 'admin_aq.q_first_table_aq', grantee => 'user_aq', grant_option => FALSE);
  dbms_aqadm.grant_queue_privilege ( privilege => 'ALL', queue_name => 'admin_aq.q_first_except', grantee => 'user_aq', grant_option => FALSE);
END;
/

BEGIN
  dbms_aqadm.grant_queue_privilege ( privilege => 'ALL', queue_name => 'admin_aq.q_second_table_aq', grantee => 'user_aq', grant_option => FALSE);
END;
/

----
--@user_aq
----

--ENQUEUE
DECLARE
  message admin_aq.type_first_table_aq;
  eq_opt dbms_aq.enqueue_options_t;
  msg_prop dbms_aq.message_properties_t;
  msg_handle raw(16);
BEGIN
  message                  := admin_aq.type_first_table_aq(1, 'rmariotti', 'info1');
  msg_prop.DELAY           := DBMS_AQ.NO_DELAY;
  msg_prop.expiration      := 15;
  msg_prop.exception_queue := 'admin_aq.q_first_except';
  DBMS_AQ.ENQUEUE(queue_name => 'admin_aq.q_first_table_aq', enqueue_options => eq_opt, message_properties=> msg_prop, payload => message, msgid => msg_handle);
  COMMIT;
END;
/

--DEQUEUE FROM QUEUE EXAMPLE
SET serveroutput ON;
DECLARE
  dopt dbms_aq.dequeue_options_t;
  msg_prop dbms_aq.message_properties_t;
  msg admin_aq.type_first_table_aq;
  msgid RAW(16);
BEGIN
  dopt.consumer_name := 'consumer_first_table1';
  dopt.visibility    := dbms_aq.immediate;
  dopt.navigation    := dbms_aq.first_message;
  dopt.wait          := 3; --timeout in seconds
  dbms_aq.dequeue(queue_name => 'admin_aq.q_first_table_aq', dequeue_options => dopt, message_properties => msg_prop, payload => msg, msgid => msgid);
  dbms_output.put_line(msg.id||' - '||msg.login||' - '||msg.operacao||' - '||msg.IP||' - '||msg.data_acesso||' - '||msg.parametros||' - '||msg.nome_arquivo_xml);
END;
/


--DEQUEUE FROM EXCEPTION QUEUE EXAMPLE
SET serveroutput ON;
DECLARE
  dopt dbms_aq.dequeue_options_t;
  msg_prop dbms_aq.message_properties_t;
  msg admin_aq.type_first_table_aq;
  msgid RAW(16);
BEGIN
  dopt.visibility    := dbms_aq.immediate;
  dopt.navigation    := dbms_aq.first_message;
  dopt.wait          := 3; --timeout in seconds
  dbms_aq.dequeue(queue_name => 'admin_aq.q_first_except', dequeue_options => dopt, message_properties => msg_prop, payload => msg, msgid => msgid);
  dbms_output.put_line(msg.id||' - '||msg.login||' - '||msg.operacao||' - '||msg.IP||' - '||msg.data_acesso||' - '||msg.parametros||' - '||msg.nome_arquivo_xml);
END;
/

--if you want to check all the messages, just run
--SELECT * FROM ADMIN_AQ.AQ$TB_WS_LOG_ACESSO_AQ;
