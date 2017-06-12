# session status
select datname, usename, application_name, client_addr IP, query_start,
date_part('second', age(now(),query_start)) time_exec, waiting,
state, query
from pg_stat_activity
where state !='idle';

# check queries which are locking tables
SELECT blockeda.pid AS blocked_pid, blockeda.query as blocked_query,
  blockinga.pid AS blocking_pid, blockinga.query as blocking_query
FROM pg_catalog.pg_locks blockedl
JOIN pg_stat_activity blockeda ON blockedl.pid = blockeda.pid
JOIN pg_catalog.pg_locks blockingl ON(blockingl.transactionid=blockedl.transactionid
  AND blockedl.pid != blockingl.pid)
JOIN pg_stat_activity blockinga ON blockingl.pid = blockinga.pid
WHERE NOT blockedl.granted;

