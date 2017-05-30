stage ('Build and test') {
  timeout(75) {
    node {
      sh 'sudo -i chown -R ubuntu:ubuntu /home/ubuntu/'
      sh 'npm config set registry http://registry.npmjs.org/'
      checkout scm
      sh 'mvn clean test -DskipITs-B -U -P tinker -Djetty.log.level=WARNING -Djetty.log.appender=STDOUT'
    }
  }
}
