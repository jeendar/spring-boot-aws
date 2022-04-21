#!/bin/bash

# Description	Shell script to update the local maven settings to the one provided
#                Put the following lines in buildspec.yaml to obtain the maven settings from the secrets manager
#                env: 
#	                secrets-manager:
#   	 				MAVEN_SETTINGS: /developer/stratocrest/artifactory/maven/settings.xml   
# $MAVEN_SETTINGS - maven settings file see also: https://github.stratocrest.com/stratocrest-be-engineering/be.stratocrest.ee.maven_testproject
# RETURN 		- no output

echo "$MAVEN_SETTINGS" > /root/.m2/settings.xml
 