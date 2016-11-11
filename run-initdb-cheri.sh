#!/bin/sh
rm -rf /home/postgres/postgres-test-cheri/instance/data
"/postgres/cheri/bin/initdb" -D "/home/postgres/postgres-test-cheri/instance/data" --no-clean --no-sync --no-locale --debug --no-sync "$@"
