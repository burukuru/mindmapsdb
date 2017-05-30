stage ('Build and test') {
  node('ec2-spot') {
    # Trigger on !rtg
    # Set status 'unit-test-pull-request-grakn-titan' to pending
    setGitHubPullRequestStatus (
      context: "unit-test-pull-request-grakn-titan"
      state: currentBuild.result
        )
    # Cancel previous build
    sh 'sudo -i chown -R ubuntu:ubuntu /home/ubuntu/'
    sh 'npm config set registry http://registry.npmjs.org/'
    checkout scm
    sh 'mvn clean verify -P titan,docker -U -Djetty.log.level=WARNING -Djetty.log.appender=STDOUT'
    # Set status 'unit-test-pull-request-grakn-titan' to complete
    setGitHubPullRequestStatus (
      context: "unit-test-pull-request-grakn-titan"
      state: currentBuild.result
        )
    # Notify Slack on abort/fail/success/unstable
    # flaky tests
  }
}

stage ('Deploy to staging') {
  node('agent1') {
    ansiblePlaybook(
        inventory: '/home/jenkins/infrastructure/onpremise/ci/inventory',
        playbook: '/home/jenkins/infrastructure/onpremise/ci/site.yml',
        extras: '-u root -e '{grakn_engine_taskmanager_implementation: ai.grakn.engine.tasks.manager.StandaloneTaskManager}' -e grakn_engine_version=$POM_VERSION -e '{redeploy: "true"}' -e grakn_download_url="$BUILD_URL/ai.grakn$grakn-dist/artifact/ai.grakn/grakn-dist/$POM_VERSION/grakn-dist-$POM_VERSION.tar.gz"'
        )
  }
}
