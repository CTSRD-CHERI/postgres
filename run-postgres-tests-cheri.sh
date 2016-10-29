#!/bin/sh
set -e
# rm -rf /root/postgres-test-cheri
mkdir -p $HOME/postgres-test-cheri/output/sql
mkdir -p $HOME/postgres-test-cheri/output/expected
mkdir -p $HOME/postgres-test-cheri/instance
/postgres/cheri/lib/pgxs/src/test/regress/pg_regress --inputdir=/postgres/cheri/lib/regress/ --bindir=/postgres/cheri/bin --dlpath=/postgres/cheri/lib  --schedule=/postgres/cheri/lib/regress/serial_schedule --no-locale --outputdir=$HOME/postgres-test-cheri/output --temp-instance=$HOME/postgres-test-cheri/instance "$@"
