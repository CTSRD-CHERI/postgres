#!/usr/bin/env bash
CHERISDK="/home/alr48/cheri/output/sdk256/bin"
CHERIBSD_SYSROOT="/home/alr48/cheri/output/sdk256/sysroot"
export PATH=${CHERISDK}:$PATH
export CC=${CHERISDK}/clang
export CXX=${CHERISDK}/clang++
READLINE_INCLUDE_DIR=${CHERIBSD_SYSROOT}/usr/include/edit/
COMPILE_FLAGS="--sysroot=${CHERIBSD_SYSROOT} -B${CHERISDK} -mabi=sandbox -msoft-float -mxgot -isystem ${READLINE_INCLUDE_DIR} -Wno-cheri-capability-misuse -Werror=implicit-function-declaration"
export CFLAGS=${COMPILE_FLAGS}
export CXXFLAGS=${COMPILE_FLAGS}
export LDFLAGS="--sysroot=${CHERIBSD_SYSROOT} -B${CHERISDK} -mabi=sandbox -msoft-float"
# env | sort
./configure --host=cheri-unknown-freebsd --target=cheri-unknown-freebsd --build=x86_64-unknown-freebsd --prefix=/home/alr48/cheri/postgres
gmake -j1
