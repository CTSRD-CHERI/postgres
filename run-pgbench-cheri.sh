#!/bin/sh

/postgres/cheri/bin/postgres -D /home/postgres/postgres-test-cheri/instance/data &
sleep 30
/postgres/cheri/bin/pgbench -i postgres
/postgres/cheri/bin/pgbench -c 2 -T 180 postgres 2>&1 | tee /tmp/pgbench-results.txt
