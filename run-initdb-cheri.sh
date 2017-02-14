#!/bin/sh
if test "`whoami`" = "root"; then
	if ! pw user show postgres > /dev/null; then
		chmod +x /etc
		pw useradd -n postgres -c "Postgres test account" -s /bin/csh -m -w none
	fi
fi
rm -rf /home/postgres/postgres-test-cheri/instance/data
script_dir=`dirname $0`
echo "${script_dir}/bin/initdb" -D "/home/postgres/postgres-test-cheri/instance/data" --noclean --nosync --no-locale "$@"
"${script_dir}/bin/initdb" -D "/home/postgres/postgres-test-cheri/instance/data" --noclean --nosync --no-locale "$@"
