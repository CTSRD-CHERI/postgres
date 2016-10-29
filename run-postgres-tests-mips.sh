#!/bin/sh
set -e
# rm -rf /root/postgres-test-mips
mkdir -p $HOME/postgres-test-mips/output/sql
mkdir -p $HOME/postgres-test-mips/output/expected
mkdir -p $HOME/postgres-test-mips/instance
/postgres/mips/lib/pgxs/src/test/regress/pg_regress --inputdir=/postgres/mips/lib/regress/ --bindir=/postgres/mips/bin --dlpath=/postgres/mips/lib  --schedule=/postgres/mips/lib/regress/serial_schedule --no-locale --outputdir=$HOME/postgres-test-mips/output --temp-instance=$HOME/postgres-test-mips/instance "$@"
