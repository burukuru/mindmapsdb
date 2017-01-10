FROM graknlabs/jenkins-base

ENV WORKSPACE $WORKSPACE
COPY . /grakn-src/
WORKDIR /grakn-src/
RUN mvn install -DskipTests=True -DskipITs=True
