#!/bin/sh -xe

POSTGRES_ROOT="/postgres/cheri"
POSTGRES_DATA="/tmp/postgres/postgres-test-cheri/instance/data"
POSTGRES="${POSTGRES_ROOT}/bin/postgres"
INITDB="${POSTGRES_ROOT}/bin/initdb"
PGCTL="${POSTGRES_ROOT}/bin/pg_ctl"
PGBENCH="${POSTGRES_ROOT}/bin/pgbench"
NTIMES=10

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

if [ -e "${POSTGRES_DATA}" ]; then
	echo "${0}: ${POSTGRES_DATA} already exists, initdb not required"
else
	echo "${0}: ${POSTGRES_DATA} does not exist, running initdb..."
	echo "Free disk space:"
	df -h || true
	${INITDB} -D "${POSTGRES_DATA}" --noclean --nosync --no-locale "$@"
fi

echo "${0}: starting postgres..."
${PGCTL} start -w -D "${POSTGRES_DATA}"

echo "${0}: running benchmark ${NTIMES} times..."
${PGBENCH} -i postgres
for i in `jot ${NTIMES}`; do
	${PGBENCH} -c 2 -T 180 postgres 2>&1 | tee /tmp/pgbench-results.txt
done

echo "${0}: stopping postgres..."
${PGCTL} stop -D "${POSTGRES_DATA}"

echo "${0}: done"
