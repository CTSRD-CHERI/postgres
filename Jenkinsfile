stage("Build") {
  
    def cleanupScript = '''
# remove the 600+ useless header files
rm -rfv tarball/opt/*/include
# save some space (not sure we need all those massive binaries anyway)
cheri-unknown-freebsd-strip tarball/opt/*/bin/*
cheri-unknown-freebsd-strip tarball/opt/*/*/pgxs/src/test/regress/pg_regress
'''
    cheribuildProject(name: 'postgres', extraArgs: '--with-libstatcounters', beforeTarball: cleanupScript,
                      testScript: 'cd /opt/$CPU/ && sh -xe ./nginx-benchmark.sh')
}
