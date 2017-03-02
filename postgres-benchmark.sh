#!/bin/sh -e

POSTGRES_ROOT="/postgres/cheri"
POSTGRES_DATA="/home/postgres/postgres-test-cheri/instance/data"
POSTGRES="${POSTGRES_ROOT}/bin/postgres"
INITDB="${POSTGRES_ROOT}/bin/initdb"
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

echo "${0}: postgres binary details:"
file "${POSTGRES}"

if [ -e "${POSTGRES_DATA}" ]; then
	echo "${0}: ${POSTGRES_DATA} already exists, initdb not required"
else
	echo "${0}: ${POSTGRES_DATA} does not exist, running initdb..."
	${INITDB} -D "${POSTGRES_DATA}" --noclean --nosync --no-locale "$@"
fi

echo "${0}: starting postgres..."
${POSTGRES} -D "${POSTGRES_DATA}" &
sleep 30
echo "${0}: running benchmark..."
${PGBENCH} -i postgres
${PGBENCH} -c 2 -T 180 postgres 2>&1 | tee /tmp/pgbench-results.txt
echo "${0}: done"
