#!/bin/bash

SCRIPT_DIR=$(dirname $0)
GRAKN_TEST_PROFILE=$1

echo "" > /tmp/grakn_mvn_docker_test_list
for MODULE_DIR in $(find "$SCRIPT_DIR"/../../* -maxdepth 0 -type d)
do
  MODULE=$(basename $MODULE_DIR)
  find $MODULE_DIR -name '*Test.java' -o -name '*IT.java' | xargs --no-run-if-empty -n1 basename | sed -e "s#^#$MODULE #" -e 's#\.java##' >> /tmp/grakn_mvn_docker_test_list
done
parallel --jobs 75% --no-run-if-empty --colsep ' ' "/usr/bin/docker run -i -v "$SCRIPT_DIR"/../../grakn-test/target/surefire-reports:/grakn-src/grakn-test/target/surefire-reports/ -w /grakn-src/ graknlabs/jenkins-with-src-compiled:latest mvn test -DfailIfNoTests=false -Dsurefire.rerunFailingTestsCount=2 -pl {1} -Dtest={2} -P"${GRAKN_TEST_PROFILE}"" < /tmp/grakn_mvn_docker_test_list
rm /tmp/grakn_mvn_docker_test_list
