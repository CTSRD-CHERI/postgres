properties([
    disableConcurrentBuilds(),
    pipelineTriggers([githubPush()]),
])

def cleanupScript = '''
# remove the 600+ useless header files
rm -rfv tarball/opt/*/include
# save some space (not sure we need all those massive binaries anyway)
# cheri-unknown-freebsd
find tarball/opt/*/bin/* -print0 | xargs -n 1 -0 strip
strip tarball/opt/*/*/postgresql/pgxs/src/test/regress/pg_regress
'''

cheribuildProject(name: 'postgres', extraArgs: '--with-libstatcounters --postgres/no-debug-info --postgres/no-assertions', beforeTarball: cleanupScript,
                  testScript: 'cd /opt/$CPU/ && sh -xe ./run-postgres-tests.sh',
                  beforeBuild: 'apt-get install -y libarchive13; ls -la $WORKSPACE',
                  // Postgres tests need the full disk image (they invoke diff -u)
                  minimalTestImage: false, /* targets: ['mips'] */
                  testTimeout: 4 * 60 * 60, // increase the test timeout to 4 hours (CHERI can take a loooong time)
                  /* sequential: true, // for now run all in order until we have it stable */
                 )
