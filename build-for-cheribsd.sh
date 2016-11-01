#!/usr/bin/env bash
set -e
CHERISDK="/home/alr48/cheri/output/sdk256/bin"
CHERIBSD_SYSROOT="/home/alr48/cheri/output/sdk256/sysroot"
export PATH=${CHERISDK}:$PATH
export CC=${CHERISDK}/clang
export CXX=${CHERISDK}/clang++
READLINE_INCLUDE_DIR=${CHERIBSD_SYSROOT}/usr/include/edit/
COMMON_FLAGS="--sysroot=${CHERIBSD_SYSROOT} -B${CHERISDK} -target cheri-unknown-freebsd -mabi=sandbox -msoft-float -mxgot -O0 -DUSE_ASSERT_CHECKING -G0"
COMPILE_FLAGS="${COMMON_FLAGS} -isystem ${READLINE_INCLUDE_DIR} -Werror=cheri-capability-misuse -Werror=implicit-function-declaration -Werror=format -Werror=undefined-internal"
# export CFLAGS=${COMPILE_FLAGS}
# export CXXFLAGS=${COMPILE_FLAGS}
# export CPPFLAGS=${COMMON_FLAGS}
# export LDFLAGS="${COMMON_FLAGS} -pthread"
# LDFLAGS_EX  extra linker flags for linking executables only
# LDFLAGS_SL  extra linker flags for linking shared libraries only
# env | sort
# more minimal: --without-libxml --without-readline --without-gssapi
env "CFLAGS=${COMPILE_FLAGS}" "CXXFLAGS=${COMPILE_FLAGS}" "CPPFLAGS=${COMMON_FLAGS}" "LDFLAGS=${COMMON_FLAGS} -pthread" "LDFLAGS_EX=-static" ./configure --host=cheri-unknown-freebsd --target=cheri-unknown-freebsd --build=x86_64-unknown-freebsd --prefix=/postgres/cheri/ --enable-debug --without-libxml --without-readline --without-gssapi
INSTALL_DIR=/exports/users/alr48
gmake -j16
gmake install DESTDIR=${INSTALL_DIR}
gmake -C src/test/regress install-tests DESTDIR=${INSTALL_DIR}

function do_objdump() {
    #echo "$CHERISDK/objdump -xrslSD  $1/$2 > $2.cheri.dump"
    #$CHERISDK/objdump -xrslSD $1/$2 > $2.cheri.dump
    echo "$CHERISDK/objdump -rlSd  $1/$2 > $2.cheri.dump"
    $CHERISDK/objdump -rlSd $1/$2 > $2.cheri.dump
}

do_objdump ./src/test/regress pg_regress
do_objdump ./src/bin/initdb initdb
do_objdump ./src/backend postgres


cp -fv run-postgres-tests-cheri.sh "${INSTALL_DIR}/postgres/run-postgres-tests-cheri.sh"
