#!/bin/sh
set -e
# rm -rf /root/postgres-test-mips
mkdir -p $HOME/postgres-test-mips/output/sql
mkdir -p $HOME/postgres-test-mips/output/expected
mkdir -p $HOME/postgres-test-mips/instance
cd /root/postgres-test-mips
/root/postgres-mips/lib/pgxs/src/test/regress/pg_regress --inputdir=/root/postgres-mips/lib/regress/ --bindir=/root/postgres-mips/bin --dlpath=/root/postgres-mips/lib  --schedule=/root/postgres-mips/lib/regress/serial_schedule --no-locale --outputdir=$HOME/postgres-test-mips/output --temp-instance=$HOME/postgres-test-mips/instance "$@"
