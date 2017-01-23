#!/bin/bash

SCRIPT_DIR=$(dirname $0)
GRAKN_TEST_PROFILE=$1

find "$SCRIPT_DIR"/../../grakn-test/ -name '*Test.java' -o -name '*IT.java' | xargs -n1 basename | sed -e 's/\.java//' > /tmp/grakn_mvn_docker_test_list
parallel "/usr/bin/docker run -i -v "$SCRIPT_DIR"/../../grakn-test/target/surefire-reports:/grakn-src/grakn-test/target/surefire-reports/ -w /grakn-src/ graknlabs/jenkins-with-src-compiled:latest mvn test -DfailIfNoTests=false -Dtest={} -P"${GRAKN_TEST_PROFILE}" -pl grakn-test" < /tmp/grakn_mvn_docker_test_list
