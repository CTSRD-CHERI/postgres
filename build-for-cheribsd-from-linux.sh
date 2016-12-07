#!/usr/bin/env bash
set -e
CHERISDK="${CHERI_SDK:-/build/ctsrd/sdk256}/bin"
CHERIBSD_SYSROOT="${CHERISDK}/../sysroot"
export PATH=${CHERISDK}:$PATH
export CC=${CHERISDK}/clang
export CXX=${CHERISDK}/clang++
READLINE_INCLUDE_DIR=${CHERIBSD_SYSROOT}/usr/include/edit/
COMMON_FLAGS="-pipe --sysroot=${CHERIBSD_SYSROOT} -B${CHERISDK} -target cheri-unknown-freebsd -mabi=sandbox -msoft-float -mxgot -O0 -DUSE_ASSERT_CHECKING -G0"
COMPILE_FLAGS="${COMMON_FLAGS} -isystem ${READLINE_INCLUDE_DIR} -Werror=cheri-capability-misuse -Werror=implicit-function-declaration -Werror=format -Werror=undefined-internal"
# export CFLAGS=${COMPILE_FLAGS}
# export CXXFLAGS=${COMPILE_FLAGS}
# export CPPFLAGS=${COMMON_FLAGS}
# export LDFLAGS="${COMMON_FLAGS} -pthread"
# LDFLAGS_EX  extra linker flags for linking executables only
# LDFLAGS_SL  extra linker flags for linking shared libraries only
# env | sort
# more minimal: --without-libxml --without-readline --without-gssapi
env PRINTF_SIZE_T_SUPPORT=yes "ZIC=/usr/sbin/zic" "CFLAGS=${COMPILE_FLAGS}" "CXXFLAGS=${COMPILE_FLAGS}" "CPPFLAGS=${COMMON_FLAGS}" "LDFLAGS=${COMMON_FLAGS} -pthread -static -fuse-ld=lld -Wl,-melf64btsmip_cheri_fbsd" "LDFLAGS_EX=-static" ./configure --host=cheri-unknown-freebsd --target=cheri-unknown-freebsd --build=x86_64-unknown-linux-gnu --prefix=/postgres/cheri/ --enable-debug --without-libxml --without-readline --without-gssapi
INSTALL_DIR=${PSOTGRES_INSTALL_DIR:-/build/ctsrd/postgres-install}
gmake -j8
gmake install DESTDIR=${INSTALL_DIR}
gmake -C src/test/regress install-tests DESTDIR=${INSTALL_DIR}
echo "$CHERISDK/objdump -xrslSD ./src/test/regress/pg_regress > pg_regress.cheri.dump"
# gmake -C src/test/regress
$CHERISDK/objdump -xrslSD ./src/test/regress/pg_regress > pg_regress.cheri.dump
cp -fv run-postgres-tests-cheri.sh "${INSTALL_DIR}/postgres/run-postgres-tests-cheri.sh"
