#!/bin/bash
function buildKeycloak() {
echo ""
echo "--------- Build Keycloak -----------"
pushd ../keycloak
./mvnw -pl quarkus/deployment,quarkus/dist -am -DskipTests clean install
RC=$?
popd
if [ $RC -ne 0 ] ; then
	echo "Keycloak build failed: $RC"
	exit $RC
fi
}

function extractArchive() {
echo ""
echo "--------- extract archive -----------"
rm -rf keycloak-999.0.0-SNAPSHOT
tar -xzf ../keycloak/quarkus/dist/target/keycloak-999.0.0-SNAPSHOT.tar.gz
curl -L https://repo1.maven.org/maven2/com/nuodb/jdbc/nuodb-jdbc/24.2.1/nuodb-jdbc-24.2.1.jar -o keycloak-999.0.0-SNAPSHOT/providers/nuodb-jdbc-24.2.1.jar
curl -L https://repo1.maven.org/maven2/com/nuodb/hibernate/nuodb-hibernate/23.1.0-hib6/nuodb-hibernate-23.1.0-hib6.jar -o keycloak-999.0.0-SNAPSHOT/providers/nuodb-hibernate-23.1.0-hib6.jar
chmod 644 keycloak-999.0.0-SNAPSHOT/providers/nuodb-jdbc-24.2.1.jar
chmod 644 keycloak-999.0.0-SNAPSHOT/providers/nuodb-hibernate-23.1.0-hib6.jar
KC_HEALTH_ENABLED=true \
KC_METRICS_ENABLED=true \
keycloak-999.0.0-SNAPSHOT/bin/kc.sh build --verbose

}

function runLocal() {
#KC_DB_URL=jdbc:com.nuodb.hib://localhost:48004/db1 \
#KC_DB_DRIVER=com.nuodb.hibernate.NuoHibernateDriver \
pushd keycloak-999.0.0-SNAPSHOT
KC_BOOTSTRAP_ADMIN_USERNAME=admin \
KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
PROXY_ADDRESS_FORWARDING=true \
KC_DB=nuodb \
KC_DB_DRIVER=com.nuodb.jdbc.DataSource \
KC_DB_URL=jdbc:nuodb://localhost:48004/db1 \
KC_DB_USERNAME=dba \
KC_DB_PASSWORD=passw0rd \
        bin/kc.sh \
        start-dev --verbose
popd
}

function runDebug() {
#KC_DB_URL=jdbc:com.nuodb.hib://localhost:48004/db1 \
#KC_DB_DRIVER=com.nuodb.hibernate.NuoHibernateDriver \
pushd keycloak-999.0.0-SNAPSHOT
KC_BOOTSTRAP_ADMIN_USERNAME=admin \
KC_BOOTSTRAP_ADMIN_PASSWORD=admin \
PROXY_ADDRESS_FORWARDING=true \
KC_DB=nuodb \
KC_DB_DRIVER=com.nuodb.jdbc.DataSource \
KC_DB_URL=jdbc:nuodb://localhost:48004/db1 \
KC_DB_USERNAME=dba \
KC_DB_PASSWORD=passw0rd \
JAVA_OPTS="-Djava.util.logging.manager=org.apache.logging.log4j.jul.LogManager -Dliquibase.sql.logLevel=DEBUG -agentlib:jdwp=transport=dt_socket,server=y,suspend=y,address=*:5005" bin/kc.sh \
        start-dev --verbose
popd
}

function help() {
	echo "$0 buildKeycloak"
	echo "$0 extractArchive"
	echo "$0 runLocal"
	echo "$0 runDebug"
	echo "$0 kill_kc"
	echo "$0 start_nuodb"
	echo "$0 stop_nuodb"
	echo "$0 start_nuodb buildKeycloak extractArchive runLocal"
}

function startNuodb() {
	pushd ../nuodb/dist
	./etc/nuoadmin start
	mkdir ./var/db1
	./bin/nuocmd create archive --db-name db1 --server-id nuoadmin-0 --archive-path ./var/db1
	./bin/nuocmd create database --db-name db1 --dba-user dba --dba-password passw0rd
	./bin/nuocmd start process --db-name db1 --server-id nuoadmin-0
	RC=1
	while [ $RC -ne 0 ] ; do
		echo "SELECT * FROM DUAL;" | ./bin/nuosql db1 --user dba --password passw0rd
		RC=$?
		if [ $RC -ne 0 ] ; then
			echo "Retrying SQL connection..."
			sleep 5
		fi
	done
	popd
}

function stopNuodb() {
	pushd ../nuodb/dist
	./bin/nuocmd shutdown database --db-name db1
	./bin/nuocmd delete database --db-name db1
	./etc/nuoadmin stop
	rm ./var/opt/raftlog
	rm -r ./var/db1
	popd
}

if [ "$1" = "" ] ; then
	help
	exit 1
fi

while [ "$1" != "" ] ; do
if [ "$1" = "buildKeycloak" ] ; then
	buildKeycloak
elif [ "$1" = "extractArchive" ] ; then
	extractArchive
elif [ "$1" = "runLocal" ] ; then
	runLocal
elif [ "$1" = "runDebug" ] ; then
	runDebug
elif [ "$1" = "kill_kc" ] ; then
        ps -ef | grep kc | grep -v -e grep | awk ' { print $2 } ' | xargs kill -9
elif [ "$1" = "stop_nuodb" ] ; then
	stopNuodb
elif [ "$1" = "start_nuodb" ] ; then
	startNuodb
else
	echo "invalid option: $1"
	help
	exit 1
fi
shift
done
