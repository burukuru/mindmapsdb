stage ('Build and test') {
  node {
    // Trigger on !rtg
    // Set status 'unit-test-pull-request-grakn-titan' to pending
    // Cancel previous build
    sh 'npm config set registry http://registry.npmjs.org/'
    checkout scm
    sh "mvn versions:set -DnewVersion=${env.BRANCH_NAME} -DgenerateBackupPoms=false"
    sh 'mvn clean package -DskipTests -U -Djetty.log.level=WARNING -Djetty.log.appender=STDOUT'
    // Set status 'unit-test-pull-request-grakn-titan' to complete
    // Notify Slack on abort/fail/success/unstable
    // flaky tests
    archiveArtifacts artifacts: 'grakn-dist/target/grakn-dist*.tar.gz'
  }
}

//stage ('Deploy to staging') {
//  node('agent') {
//    sh "git clone git@github.com:graknlabs/infrastructure.git || true"
//    ansiblePlaybook(
//        inventory: '$WORKSPACE/infrastructure/onpremise/ci/inventory',
//        playbook: '$WORKSPACE/infrastructure/onpremise/ci/site.yml',
//        extras: '-u root -e grakn_engine_version=$POM_VERSION -e \'{redeploy: "true"}\' -e grakn_download_url="$BUILD_URL/ai.grakn$grakn-dist/artifact/ai.grakn/grakn-dist/$POM_VERSION/grakn-dist-$POM_VERSION.tar.gz"'
//        )
//  }
//}
