#!/bin/bash

# Description	Shell script to install the stratocrest root certificate in the trust store of the java JRE, the script can handle Java 8 and Java 11 and above installation locations
# $ 			- no input
# export KEYSTORE - location of the found keystore
# RETURN 		- no output

echo "$ROOT_CA" > stratocrest-Enterprise-Root-CA.cer
echo "Verifying dates of root certificate"
openssl x509 -noout -in stratocrest-Enterprise-Root-CA.cer -dates

echo "Verifying subject of the root certificate"
SUBJECT=$(openssl x509 -noout -subject -in stratocrest-Enterprise-Root-CA.cer)
if [[ $SUBJECT != *"stratocrest-Enterprise-Root-CA"* ]]; then
  echo "The given root certificate is not correct!"
  exit 1
fi
echo "Correctly found 'stratocrest-Enterprise-Root-CA' as part of the subject of the stratocrest root certificate"

echo $JAVA_HOME

KEYSTORE=$JAVA_HOME/jre/lib/security/cacerts

if [ ! -f $KEYSTORE ]; then
    echo "Java keystore not found at $KEYSTORE, searching in next folder"
    KEYSTORE=$JAVA_HOME/lib/security/cacerts
fi

if [ ! -f $KEYSTORE ]; then
    echo "Java keystore not found at $KEYSTORE, exiting with error code"
	exit 1
fi

echo "Java keytore found at $KEYSTORE, installing certificates and exporting environmental variable KEYSTORE..."

export KEYSTORE=$KEYSTORE

echo "Installing root certificate"
echo y | keytool -import -v -trustcacerts -alias stratocrestroot -file stratocrest-Enterprise-Root-CA.cer -keystore $KEYSTORE -storepass changeit

echo "Certicates are installed in keystore found at $KEYSTORE" 
