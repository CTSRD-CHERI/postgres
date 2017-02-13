#!/usr/bin/env bash
set -e
CHERI_ROOT="${HOME}/cheri"
CHERISDK="${CHERI_ROOT}/output/sdk256/bin"
CHERIBSD_SYSROOT="${CHERI_ROOT}/output/sdk256/sysroot"
export PATH=${CHERISDK}:${CHERILDDIR}:$PATH
export CC=${CHERISDK}/clang
export CXX=${CHERISDK}/clang++
READLINE_INCLUDE_DIR=${CHERIBSD_SYSROOT}/usr/include/edit/
COMMON_FLAGS="-pipe --sysroot=${CHERIBSD_SYSROOT} -B${CHERISDK} -target cheri-unknown-freebsd -mabi=sandbox -msoft-float -mxgot -O0 -static -DUSE_ASSERT_CHECKING  -G0 -integrated-as"
COMPILE_FLAGS="${COMMON_FLAGS} -isystem ${READLINE_INCLUDE_DIR} -Werror=cheri-capability-misuse -Werror=implicit-function-declaration -Werror=format -Werror=undefined-internal -Werror=incompatible-pointer-types"
# export CFLAGS=${COMPILE_FLAGS}
# export CXXFLAGS=${COMPILE_FLAGS}
# export CPPFLAGS=${COMMON_FLAGS}
# export LDFLAGS="${COMMON_FLAGS} -pthread"
# LDFLAGS_EX  extra linker flags for linking executables only
# LDFLAGS_SL  extra linker flags for linking shared libraries only
# env | sort
# more minimal: --without-libxml --without-readline --without-gssapi
# TODO: static? "LDFLAGS_EX=-static"
env PRINTF_SIZE_T_SUPPORT=yes "CFLAGS=${COMPILE_FLAGS}" "CXXFLAGS=${COMPILE_FLAGS}" "CPPFLAGS=${COMMON_FLAGS}" "LDFLAGS=${COMMON_FLAGS} -pthread -Wl,-melf64btsmip_cheri_fbsd" sh ./configure --host=cheri-unknown-freebsd --target=cheri-unknown-freebsd --build=x86_64-unknown-freebsd --prefix=/postgres/cheri/ --enable-debug --without-libxml --without-readline --without-gssapi
#INSTALL_DIR=/exports/users/alr48
INSTALL_DIR=${CHERI_ROOT}/output/rootfs256
#gmake -j16
gmake
gmake install DESTDIR=${INSTALL_DIR}
gmake -C src/test/regress install-tests DESTDIR=${INSTALL_DIR}

function do_objdump() {
    #echo "$CHERISDK/objdump -xrslSD  $1/$2 > $2.cheri.dump"
    #$CHERISDK/objdump -xrslSD $1/$2 > $2.cheri.dump
    echo "$CHERISDK/objdump -rlSd  $1/$2 > $2.cheri.dump"
    $CHERISDK/objdump -rlSd $1/$2 > $2.cheri.dump
}

#do_objdump ./src/test/regress pg_regress
do_objdump ./src/bin/initdb initdb
#do_objdump ./src/backend postgres


cp -fv run-postgres-tests-cheri.sh "${INSTALL_DIR}/postgres/run-postgres-tests-cheri.sh"
cp -fv run-initdb-cheri.sh "${INSTALL_DIR}/postgres/run-initdb-cheri.sh"

