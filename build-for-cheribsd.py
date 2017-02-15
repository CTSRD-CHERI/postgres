#!/usr/bin/env python3
import argparse
import os
import sys
import shlex

from subprocess import check_call
from pathlib import Path

def defaultNumberOfMakeJobs():
    makeJobs = os.cpu_count()
    if makeJobs > 24:
        # don't use up all the resources on shared build systems
        makeJobs = 16
    return makeJobs

parser = argparse.ArgumentParser(
    # ... other options ...
    formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument("--cheri-root", default=os.path.expanduser("~/cheri"))
parser.add_argument("--install-root", help="root directory for postgres install (will be installed to a target-specific subdir)", default=os.path.expanduser("~/cheri/output/postgres-install"))
parser.add_argument("--reconfigure", action="store_true")
parser.add_argument("--build_jobs", "-j", type=int, default=min(16, os.cpu_count()), help="number of make jobs")
target = parser.add_mutually_exclusive_group()
possible_targets = ["mips", "cheri128", "cheri256"]
target.add_argument("--build-target", dest="build_target", choices=possible_targets, default="cheri256")
target.add_argument("--cheri-256", "--256", dest="build_target", action="store_const", const="cheri256")
target.add_argument("--cheri-128", "--128", dest="build_target", action="store_const", const="cheri128")
target.add_argument("--mips", dest="build_target", action="store_const", const="mips")
args = parser.parse_args()
print(args)

cheri_root = Path(args.cheri_root)
if args.build_target == "cheri256":
    cheri_sdk = cheri_root / "output/sdk256"
    target_flags = ["-target", "cheri-unknown-freebsd", "-mabi=sandbox"]
    target_ld_flags = ["-Wl,-melf64btsmip_cheri_fbsd"]
elif args.build_target == "cheri128":
    cheri_sdk = cheri_root / "output/sdk128"
    target_flags = ["-target", "cheri-unknown-freebsd", "-mabi=sandbox", "-mllvm", "-cheri128"]
    target_ld_flags = ["-Wl,-melf64btsmip_cheri_fbsd"]
elif args.build_target == "mips":
    target_flags = ["-target", "mips64-unknown-freebsd", "-mabi=n64"]
    target_ld_flags = ["-Wl,-melf64btsmip_fbsd"]
    # use the MIPS binaries from 256 bit sysroot
    cheri_sdk = cheri_root / "output/sdk256"
else:
    sys.exit("logic error")
cheri_sysroot = cheri_sdk / "sysroot"
optlevel = "-O0"
common_flags = [
    "-pipe",
    "-msoft-float",
    "-mxgot",
    "-static",
    "-DUSE_ASSERT_CHECKING",
    "-G0",
    "-integrated-as",
    optlevel
]
warning_flags = [
    "-Werror=cheri-capability-misuse",
    "-Werror=implicit-function-declaration",
    "-Werror=format",
    "-Werror=undefined-internal",
    "-Werror=incompatible-pointer-types",
]
readline_include_dir = str(cheri_sysroot / "usr/include/edit")
compiler_path_flags = ["--sysroot=" + str(cheri_sysroot), "-B" + str(cheri_sdk), "-isystem ", readline_include_dir]
compile_flags = compiler_path_flags + common_flags + warning_flags + target_flags
# LDFLAGS_EX  extra linker flags for linking executables only
# LDFLAGS_SL  extra linker flags for linking shared libraries only
# TODO: try building shared once linker works
ld_flags = ["-pthread", "-static"] + target_ld_flags
os.environ["CC"] = str(cheri_sdk / "bin/clang")
os.environ["CXX"] = str(cheri_sdk / "bin/clang++")
os.environ["PATH"] = "%s:%s" % (cheri_sdk / "bin", os.environ["PATH"])
# export CFLAGS=${COMPILE_FLAGS}
# export CXXFLAGS=${COMPILE_FLAGS}
# export CPPFLAGS=${COMMON_FLAGS}
# export LDFLAGS="${COMMON_FLAGS} -pthread -static"
configure_env = os.environ.copy()
configure_env.update({
    "PRINTF_SIZE_T_SUPPORT": "yes",
    "CFLAGS": " ".join(compile_flags),
    "CXXFLAGS": " ".join(compile_flags),
    "CPPFLAGS": " ".join(compiler_path_flags),
    "LDFLAGS": " ".join(ld_flags),

})


src_root = Path(__file__).parent  # type: Path
os.chdir(str(src_root))
# check_call(["env"], env=configure_env)
install_prefix = "/postgres/" + args.build_target
if args.reconfigure or not (src_root / "GNUmakefile").exists():
    check_call(["sh", "./configure",
                "--host=cheri-unknown-freebsd", "--target=cheri-unknown-freebsd", "--build=x86_64-unknown-freebsd",
                "--prefix=" + install_prefix,
                "--enable-debug",
                "--without-libxml", "--without-readline", "--without-gssapi",
                ], env=configure_env)

check_call(["gmake", "-j", str(args.build_jobs)])
check_call(["gmake", "install", "DESTDIR=" + args.install_root])
check_call(["gmake", "-C", "src/test/regress", "install-tests", "DESTDIR=" + args.install_root])


def do_objdump(executable: Path):
    cmd = [str(cheri_sdk / "bin/objdump"), "-rlSd", str(executable)]
    print("Creating dump of", executable)
    with (src_root / (executable.name + ".dump")).open("w+") as output:
        check_call(cmd, stdout=output)


do_objdump(src_root / "src/bin/initdb/initdb")
do_objdump(src_root / "src/bin/initdb/initdb.o")
do_objdump(src_root / "src/test/regress/pg_regress")
do_objdump(src_root / "src/backend/postgres")
# for i in possible_targets:
check_call(["cp", "-fv", str(src_root / "run-initdb-cheri.sh"), args.install_root + install_prefix + "/run-initdb.sh"])
print("Done.")
