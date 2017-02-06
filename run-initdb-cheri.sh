#!/bin/sh
rm -rf /home/postgres/postgres-test-cheri/instance/data
"/postgres/cheri/bin/initdb" -D "/home/postgres/postgres-test-cheri/instance/data" --noclean --nosync --no-locale "$@"
