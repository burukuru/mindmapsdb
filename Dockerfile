FROM openjdk:8-jdk

ENV DOCKER_GRAKN_HOME=/grakn
ENV STORAGE_CONFIG=${DOCKER_GRAKN_HOME}/services/cassandra/

RUN apt-get update \
  && apt-get install -y curl maven git \
  && curl -sL https://deb.nodesource.com/setup_6.x | bash - \
  && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
  && apt-get update && apt-get install -y nodejs yarn \
  && git clone --depth 1 https://github.com/graknlabs/grakn.git grakn-src \
  && cd grakn-src \
  && mvn clean package -DskipTests -Dmaven.javadoc.skip=true \
  && GRAKN_VERSION=$(mvn -q -Dexec.executable="echo" -Dexec.args='${project.version}' --non-recursive org.codehaus.mojo:exec-maven-plugin:1.3.1:exec 2>/dev/null) \
  && cp grakn-dist/target/grakn-dist-${GRAKN_VERSION}.tar.gz / \
  && mkdir ${DOCKER_GRAKN_HOME} \
  && tar -C /${DOCKER_GRAKN_HOME} --strip-components 1 -xf /grakn-dist-${GRAKN_VERSION}.tar.gz \
  && rm /grakn-dist-${GRAKN_VERSION}.tar.gz \
  && sed -i -e "s#ai.grakn.engine.Grakn > /dev/null 2>\&1 \&#ai.grakn.engine.Grakn > /dev/null 2>\&1#" ${DOCKER_GRAKN_HOME}/grakn \
  && rm -rf /root/.m2/ /grakn-src \
  && apt-get remove -y nodejs yarn maven git \
  && apt-get autoremove -y \
  && apt-get purge

COPY docker-entrypoint.sh /docker-entrypoint.sh
ENTRYPOINT ["/docker-entrypoint.sh"]

EXPOSE 4567 9042 9160
WORKDIR /${DOCKER_GRAKN_HOME}
CMD ["./grakn","server","start"]
