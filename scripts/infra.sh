#!/bin/bash
echo "Checking if API Gateway already exists"
output=`aws cloudformation list-stacks --stack-status-filter "CREATE_COMPLETE" "UPDATE_COMPLETE" --query "StackSummaries[?StackName=='$EB_APIGW_CREATION_STACK_NAME'].StackName" --output text`
if [ -z "$output" ]; then
	echo "No API GW currently deployed"
	OLD_VPC_LINK=""
else
	OLD_VPC_LINK=`aws cloudformation describe-stacks --stack-name ${EB_APIGW_CREATION_STACK_NAME} --query "Stacks[0].Outputs[?OutputKey=='VpcLinkID'].OutputValue" --output text`
	echo "Found existing API GW with VPC Link=${OLD_VPC_LINK}"
fi

echo Deploying EB IAM and SG
aws cloudformation deploy --template-file templates/elastic-beanstalk-iam-sg.yaml \
--stack-name ${EB_IAM_SG_CREATION_STACK_NAME} \
--parameter-overrides \
ResourcePrefix=${RESOURCE_PREFIX} \
EBApplicationNameSuffix=${APP_NAME} \
"Environment=${ACCOUNT_ENVIRONMENT}" \
"OrganizationName=${FEATURE_TEAM}" \
VPCId=${PRIVATE_VPC} \
InstancePort=80 \
--capabilities CAPABILITY_NAMED_IAM \
--no-fail-on-empty-changeset \
--tags "${tags[@]}"

export EC2_INSTANCE_PROFILE="$(aws cloudformation describe-stacks --stack-name ${EB_IAM_SG_CREATION_STACK_NAME} --output text --query "Stacks[0].Outputs[?OutputKey=='EBEC2InstanceProfileArn'].OutputValue" --output text)"
echo ${EC2_INSTANCE_PROFILE}
export EC2_SGID="$(aws cloudformation describe-stacks --stack-name ${EB_IAM_SG_CREATION_STACK_NAME} --output text --query "Stacks[0].Outputs[?OutputKey=='EC2SecurityGroup'].OutputValue" --output text)"
echo ${EC2_SGID}

echo Deploying EB
aws cloudformation deploy --template-file templates/elastic-beanstalk.yaml \
--stack-name ${EB_CREATION_STACK_NAME} \
--parameter-overrides \
ResourcePrefix=${RESOURCE_PREFIX} \
EBApplicationNameSuffix=${APP_NAME} \
Stage=${STAGE} \
CodeBucketName=${ARTEFACTS_BUCKET} \
"CodeZipName=${TARGET_PLATFORM}/${WAR_FILE}" \
"Environment=${ACCOUNT_ENVIRONMENT}" \
"MstratocrestpplicationVersionAgeinDays=30" \
NotificationList=${NOTIFICATION_LIST} \
"OrganizationName=${FEATURE_TEAM}" \
"PlatformUpdateLevel=patch" \
"SolutionStack=${SOLUTION_STACK}" \
"SubnetIds=${PRIVATE_SUBNET_1},${PRIVATE_SUBNET_2}" \
VPCId=${PRIVATE_VPC} \
VPCCIDR=${PRIVATE_VPC_CIDR} \
EC2InstanceProfileArn=${EC2_INSTANCE_PROFILE} \
EC2SecurityGroupId=${EC2_SGID} \
InstancePort=80 \
ProcessPort=8080 \
--capabilities CAPABILITY_NAMED_IAM \
--no-fail-on-empty-changeset \
--tags "${tags[@]}"

echo Retrieve EB Env Name
export EB_ENV_NAME="$(aws cloudformation describe-stacks --stack-name ${EB_CREATION_STACK_NAME} --output text --query "Stacks[0].Outputs[?OutputKey=='EBEnvironment'].OutputValue" --output text)"
echo ${EB_ENV_NAME}
echo Retrieve NLB ARN
export NLB_ARN="$(aws elasticbeanstalk describe-environment-resources --environment-name ${EB_ENV_NAME} --output text --query "EnvironmentResources.LoadBalancers[0].Name" --output text)"
echo ${NLB_ARN}
export EB_URL="$(aws cloudformation describe-stacks --stack-name ${EB_CREATION_STACK_NAME} --output text --query "Stacks[0].Outputs[?OutputKey=='EBUrl'].OutputValue" --output text)"
echo ${EB_URL}

echo Deploying EB API GW using VpcEndpointId=${SHARED_API_GATEWAY_VPC_ENDPOINT_ID}
# For APIResourceName use the naming convention from: https://confluence.stratocrest.com/confluence/display/stratocrestBEAPIDESIGN/AWS+-+API+naming+convention
aws cloudformation deploy --template-file templates/elastic-beanstalk-apigw.yaml \
--stack-name ${EB_APIGW_CREATION_STACK_NAME} \
--parameter-overrides \
APIResourceName=${STAGE}-${APP_NAME}-api \
StageName=${STAGE} \
EBUrl=${EB_URL} \
NotificationList=${NOTIFICATION_LIST} \
VpcEndpointId=${SHARED_API_GATEWAY_VPC_ENDPOINT_ID} \
NLBArn=${NLB_ARN} \
ApplicationName=${APP_NAME} \
APINameSuffix=api \
AuthorizerFunction="" \
--no-fail-on-empty-changeset \
--tags "${tags[@]}"

echo deploying API
export API_ID="$(aws cloudformation describe-stacks --stack-name ${EB_APIGW_CREATION_STACK_NAME} --output text --query "Stacks[0].Outputs[?OutputKey=='ApiID'].OutputValue" --output text)"
aws apigateway create-deployment --rest-api-id ${API_ID} --stage-name ${STAGE} --description ${CODEBUILD_RESOLVED_SOURCE_VERSION}

NEW_VPC_LINK=`aws cloudformation describe-stacks --stack-name ${EB_APIGW_CREATION_STACK_NAME} --query "Stacks[0].Outputs[?OutputKey=='VpcLinkID'].OutputValue" --output text`
echo "Attempting to Delete the old VPC Link and NLB in case new ones have been created"
if [ "${OLD_VPC_LINK}" != "${NEW_VPC_LINK}" ] && [ ! -z "${OLD_VPC_LINK}" ]; then
	echo "The VPC Link has changed, attemping to delete old VPC Link and NLB"

	OLD_NLB_ARN=`aws apigateway get-vpc-link --vpc-link-id ${OLD_VPC_LINK} --query "targetArns[0]" --output text`
    echo "Old VPC Link = ${OLD_VPC_LINK}"
	echo "Old NLB Arn = ${OLD_NLB_ARN}"

	echo "Deleting old API GW VPC Link ..."
	aws apigateway delete-vpc-link --vpc-link-id ${OLD_VPC_LINK}
	while [ ! -z $(aws apigateway get-vpc-links --query "items[?id=='${OLD_VPC_LINK}'].id" --output text) ]
	do
		echo "Waiting for old API GW VPC Link to be successfully deleted ..."
		sleep 5
	done
	sleep 5

	echo "Deleting old NLB ..."
	aws elbv2 delete-load-balancer --load-balancer-arn ${OLD_NLB_ARN}
else
    echo "No change on API GW VPC Link and NLB"
fi