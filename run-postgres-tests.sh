#!/bin/sh -e

POSTGRES_ROOT="$(realpath .)"
if ! test -e "${POSTGRES_ROOT}/run-postgres-tests.sh"; then
   echo "You have to cd to the directory where $0 is located first!"
   exit 1
fi

OUTPUT_ROOT="/tmp/postgres"
POSTGRES_INSTANCE="${OUTPUT_ROOT}/postgres-test-cheri/instance"
POSTGRES_DATA="${POSTGRES_INSTANCE}/data"
OUTPUT_DIR="${OUTPUT_ROOT}/postgres-test-cheri/output"

POSTGRES="${POSTGRES_ROOT}/bin/postgres"
INITDB="${POSTGRES_ROOT}/bin/initdb"
PGCTL="${POSTGRES_ROOT}/bin/pg_ctl"
PGBENCH="${POSTGRES_ROOT}/bin/pgbench"

if test "`whoami`" = "root"; then
	if ! pw user show postgres -q > /dev/null; then
		echo "${0}: user \"postgres\" does not exist, adding..."
		pw useradd -n postgres -c "Postgres test account" -s /bin/csh -m -w none
	fi
	echo "${0}: reexecuting itself as user \"postgres\"..."
	su postgres -c "${0}"
	exit
fi


echo "${0}: uname:"
uname -a

echo "${0}: invariants/witness:"
sysctl -a | grep -E '(invariants|witness)' || true

echo "${0}: postgres binary details:"
if ! command -v file > /dev/null; then
	echo "file binary not installed"
else
	file "${POSTGRES}"
fi

rm -irf "$OUTPUT_DIR"
mkdir -p "$OUTPUT_DIR/sql"
mkdir -p "$OUTPUT_DIR/expected"

# TODO: figure out the right flags to use an existing instance
# if [ -e "${POSTGRES_DATA}" ]; then
# 	echo "${0}: ${POSTGRES_DATA} already exists, initdb not required"
# else
# 	echo "${0}: ${POSTGRES_DATA} does not exist, running initdb..."
# 	${INITDB} -D "${POSTGRES_DATA}" --noclean --nosync --no-locale "$@"
# fi

"${POSTGRES_ROOT}/lib/postgresql/pgxs/src/test/regress/pg_regress" "--inputdir=${POSTGRES_ROOT}/lib/regress/" "--bindir=${POSTGRES_ROOT}/bin" "--dlpath=${POSTGRES_ROOT}/lib"  "--schedule=${POSTGRES_ROOT}/lib/regress/cheri_schedule" --no-locale "--outputdir=$OUTPUT_DIR" "--temp-instance=$POSTGRES_INSTANCE" "$@"
