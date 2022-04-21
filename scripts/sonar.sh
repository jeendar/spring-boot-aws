#!/bin/bash
export SONAR_SCANNER_OPTS=-Djavax.net.ssl.trustStore=/opt/jvm/amazon-corretto-11/lib/security/cacerts
mvn sonar:sonar -Dsonar.host.url=$SONARQUBE_URL -Dsonar.login=$SONARQUBE_LOGIN
