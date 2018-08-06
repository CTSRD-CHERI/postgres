#!/bin/sh -xe

POSTGRES_ROOT="$(realpath .)"
POSTGRES_DATA="/tmp/postgres/postgres-test-cheri/instance/data"
POSTGRES="${POSTGRES_ROOT}/bin/postgres"
INITDB="${POSTGRES_ROOT}/bin/initdb"
PGCTL="${POSTGRES_ROOT}/bin/pg_ctl"
PGBENCH="${POSTGRES_ROOT}/bin/pgbench"
NTIMESi=10

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

export STATCOUNTERS_FORMAT=csv
export STATCOUNTERS_OUTPUT="/tmp/postgres.statcounters.csv"

if [ -e "${POSTGRES_DATA}" ]; then
	echo "${0}: ERROR: ${POSTGRES_DATA} already exists, initdb not required"
	exit 1
else
	echo "${0}: ${POSTGRES_DATA} does not exist, running initdb..."
	echo "Free disk space:"
	df -h || true
fi

echo "${0}: running benchmark ${NTIMES} times..."
if command -v jot 2>/dev/null ; then
	BENCHCOUNT="$(jot ${NTIMES})"
elif command -v seq 2>/dev/null ; then
	BENCHCOUNT="$(seq ${NTIMES})"
else
	BENCHCOUNT="1 2 3 4 5 6 7 8 9 10"
fi

for i in $BENCHCOUNT; do
	${INITDB} -D "${POSTGRES_DATA}" --noclean --nosync --no-locale "$@"
	echo "Free disk space:"
	df -h || true
	rm -rf "${POSTGRES_DATA}"
done

echo "${0}: DONE RUNNING BENCHMARKS"
