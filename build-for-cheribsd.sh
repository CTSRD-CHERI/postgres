#!/bin/sh -e

case "$1" in
	"cheri"|"")
		MABI="purecap"
		;;
	"hybrid")
		MABI="n64"
		;;
	*)
		echo 'must specify either "cheri" or "hybrid"'
		exit 1
esac

CHERI_ROOT="${HOME}/cheri"
CHERISDK="${CHERI_ROOT}/output/sdk/bin"
CHERIBSD_SYSROOT="${CHERI_ROOT}/output/rootfs-purecap128"
READLINE_INCLUDE_DIR=${CHERIBSD_SYSROOT}/usr/include/edit/
INSTALL_DIR=${CHERI_ROOT}/output/rootfs-purecap128
#CFLAGS_LIBSTATCOUNTERS="-Wl,--whole-archive -lstatcounters -Wl,--no-whole-archive"

export PATH=${CHERISDK}:${CHERILDDIR}:$PATH
export AR=${CHERISDK}/ar
export CC=${CHERISDK}/clang
export CXX=${CHERISDK}/clang++
COMMON_FLAGS="-pipe --sysroot=${CHERIBSD_SYSROOT} -B${CHERISDK} -target cheri-unknown-freebsd -mabi=${MABI} -msoft-float -O -integrated-as"
COMPILE_FLAGS="${COMMON_FLAGS} -isystem ${READLINE_INCLUDE_DIR} -Werror=cheri-capability-misuse -Werror=implicit-function-declaration -Werror=format -Werror=undefined-internal -Werror=incompatible-pointer-types"

#env PRINTF_SIZE_T_SUPPORT=yes "CFLAGS=${COMPILE_FLAGS}" "CXXFLAGS=${COMPILE_FLAGS}" "CPPFLAGS=${COMMON_FLAGS}" "LDFLAGS=${COMMON_FLAGS} ${CFLAGS_LIBSTATCOUNTERS} -fuse-ld=lld -pthread -Wl,-melf64btsmip_cheri_fbsd" sh ./configure --host=cheri-unknown-freebsd --target=cheri-unknown-freebsd --build=x86_64-unknown-freebsd --prefix=/postgres/cheri/ --without-libxml --without-readline --without-gssapi
env PRINTF_SIZE_T_SUPPORT=yes "CFLAGS=${COMPILE_FLAGS}" "CXXFLAGS=${COMPILE_FLAGS}" "CPPFLAGS=${COMMON_FLAGS}" "LDFLAGS=${COMMON_FLAGS} ${CFLAGS_LIBSTATCOUNTERS} -pthread" sh ./configure --host=cheri-unknown-freebsd --target=cheri-unknown-freebsd --build=x86_64-unknown-freebsd --prefix=/postgres/ --without-libxml --without-readline --without-gssapi
#INSTALL_DIR=/exports/users/alr48
gmake -j8 clean 
gmake -j8 all
gmake install DESTDIR=${INSTALL_DIR}
gmake -C src/test/regress install-tests DESTDIR=${INSTALL_DIR}

cp run-postgres-tests.sh "${INSTALL_DIR}/postgres/run-postgres-tests.sh"
#cp run-initdb-cheri.sh "${INSTALL_DIR}/postgres/run-initdb-cheri.sh"
#cp postgres-benchmark.sh "${INSTALL_DIR}/postgres-benchmark.sh"
#chmod 755 "${INSTALL_DIR}/postgres-benchmark.sh"
chmod -R a+rX "${INSTALL_DIR}/postgres"

