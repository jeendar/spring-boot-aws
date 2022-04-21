#!/bin/bash

# Description  Tags are read from the dynamodb table defined in the feature team account
#              The script needs to be added in the pre-build phase of the buildspec.yaml and before the infra.sh scripts 
# $1           The first parameter is the name of the dynamodb tag table.  The name of the tag table can be constructed by two env variables
#              of the build project : ${APPLICATION}-${STAGE}
# $2           Export tags as environmental variable array [true|false], default: true.  Array environmental variables are not supported on Windows.  
#              when false is given as an argument, tags can be read in other scripts with 'readarray -t tags < aws.tags' 
# RETURN       Propagate tags via aws cloudformation by :
#                   adding --tags "${tags[@]}" to the aws cloudformation deploy command
#            
#               Example : 
#                   aws cloudformation deploy --template-file templates/web-hosting-s3.yaml --stack-name ${S3_CREATION_STACK_NAME} --tags "${tags[@]}" .. 
#
#               This method of passing the tags is needed to support tag values with spaces . Simply specifying --tags $tags generates an error when tag values have spaces .

 
# Generate tag variable

exportAsEnvVariable=$2

if [ -z $exportAsEnvVariable ];then
  exportAsEnvVariable=true
fi

if [ -z $1 ];then
  echo "Tag table parameter is missing."
  exit 1
else
  tag_table_name=$1
  > aws.tags
  
  echo "Reading the tags from table $tag_table_name" 
  
  export GLOBAL_APP_TAG="$(aws dynamodb get-item --table-name ${tag_table_name} --key "{\"TagName\": {\"S\": \"global.app\"}}" | jq ".Item.TagValue.S" | sed s/\"//g)"
  if [ ! -z "$GLOBAL_APP_TAG" ]; then echo "global.app=$GLOBAL_APP_TAG" | tee -a aws.tags ; else echo "global.app empty on dynamodb"; fi
  
  export GLOBAL_DATACLASS_TAG="$(aws dynamodb get-item --table-name ${tag_table_name} --key "{\"TagName\": {\"S\": \"global.dataclass\"}}" | jq ".Item.TagValue.S" | sed s/\"//g)"
  if [ ! -z "$GLOBAL_DATACLASS_TAG" ]; then echo "global.dataclass=$GLOBAL_DATACLASS_TAG" | tee -a aws.tags ; else echo "global.dataclass empty on dynamodb"; fi
  
  export GLOBAL_DCS_TAG="$(aws dynamodb get-item --table-name ${tag_table_name} --key "{\"TagName\": {\"S\": \"global.dcs\"}}" | jq ".Item.TagValue.S" | sed s/\"//g)"
  if [ ! -z "$GLOBAL_DCS_TAG" ]; then echo "global.dcs=$GLOBAL_DCS_TAG" | tee -a aws.tags ; else echo "global.dcs empty on dynamodb"; fi
  
  export GLOBAL_ENV_TAG="$(aws dynamodb get-item --table-name ${tag_table_name} --key "{\"TagName\": {\"S\": \"global.env\"}}" | jq ".Item.TagValue.S" | sed s/\"//g)"
  if [ ! -z "$GLOBAL_ENV_TAG" ]; then echo "global.env=$GLOBAL_ENV_TAG" | tee -a aws.tags ; else echo "global.env empty on dynamodb"; fi
  
  export GLOBAL_OPCO_TAG="$(aws dynamodb get-item --table-name ${tag_table_name} --key "{\"TagName\": {\"S\": \"global.opco\"}}" | jq ".Item.TagValue.S" | sed s/\"//g)"
  if [ ! -z "$GLOBAL_OPCO_TAG" ]; then echo "global.opco=$GLOBAL_OPCO_TAG" | tee -a aws.tags ; else echo "global.opco empty on dynamodb"; fi
  
  export GLOBAL_PROJECT_TAG="$(aws dynamodb get-item --table-name ${tag_table_name} --key "{\"TagName\": {\"S\": \"global.project\"}}" | jq ".Item.TagValue.S" | sed s/\"//g)"
  if [ ! -z "$GLOBAL_PROJECT_TAG" ]; then echo "global.project=$GLOBAL_PROJECT_TAG" | tee -a aws.tags ; else echo "global.project empty on dynamodb"; fi
  
  export GLOBAL_CBP_TAG="$(aws dynamodb get-item --table-name ${tag_table_name} --key "{\"TagName\": {\"S\": \"global.cbp\"}}" | jq ".Item.TagValue.S" | sed s/\"//g)"
  if [ ! -z "$GLOBAL_CBP_TAG" ]; then echo "global.cbp=$GLOBAL_CBP_TAG" | tee -a aws.tags ; else echo "global.cbp empty on dynamodb"; fi

  export GLOBAL_BROKER_TAG="$(aws dynamodb get-item --table-name ${tag_table_name} --key "{\"TagName\": {\"S\": \"global.broker\"}}" | jq ".Item.TagValue.S" | sed s/\"//g)"
  if [ ! -z "$GLOBAL_BROKER_TAG" ]; then echo "global.broker=$GLOBAL_BROKER_TAG" | tee -a aws.tags ; else echo "global.broker empty on dynamodb"; fi
  
  export LOCAL_RESGROUP_TAG="$(aws dynamodb get-item --table-name ${tag_table_name} --key "{\"TagName\": {\"S\": \"local.res_group\"}}" | jq ".Item.TagValue.S" | sed s/\"//g)"
  if [ ! -z "$LOCAL_RESGROUP_TAG" ]; then echo "local.res_group=$LOCAL_RESGROUP_TAG" | tee -a aws.tags ; else echo "local.res_group empty on dynamodb"; fi

  export LOCAL_DATACLASS_TAG="$(aws dynamodb get-item --table-name ${tag_table_name} --key "{\"TagName\": {\"S\": \"local.dataclass\"}}" | jq ".Item.TagValue.S" | sed s/\"//g)"
  if [ ! -z "$LOCAL_DATACLASS_TAG" ]; then echo "local.dataclass=$LOCAL_DATACLASS_TAG" | tee -a aws.tags ; else echo "local.dataclass empty on dynamodb"; fi

  export LOCAL_ENV_TAG="$(aws dynamodb get-item --table-name ${tag_table_name} --key "{\"TagName\": {\"S\": \"local.env\"}}" | jq ".Item.TagValue.S" | sed s/\"//g)"
  if [ ! -z "$LOCAL_ENV_TAG" ]; then echo "local.env=$LOCAL_ENV_TAG" | tee -a aws.tags ; else echo "local.env empty on dynamodb"; fi 
  echo "Tag values read from $tag_table_name"
  
  if [ "$exportAsEnvVariable" = true ]; then
  	export tags=("global.app=${GLOBAL_APP_TAG}" "global.dataclass=${GLOBAL_DATACLASS_TAG}" "global.dcs=${GLOBAL_DCS_TAG}" "global.env=${GLOBAL_ENV_TAG}" "global.opco=${GLOBAL_OPCO_TAG}" "global.project=${GLOBAL_PROJECT_TAG}" "global.cbp=${GLOBAL_CBP_TAG}" "global.broker=${GLOBAL_BROKER_TAG}" "local.res_group=${LOCAL_RESGROUP_TAG}" "local.dataclass=${LOCAL_DATACLASS_TAG}" "local.env=${LOCAL_ENV_TAG}")
  	echo "Tag values exported as environmental variable: ${tags[@]}"
  fi

fi
