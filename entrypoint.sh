#!/bin/sh

set -e

token=`curl \
--silent \
--fail \
-H "Content-Type: application/json" \
-d '{
	"refresh_token": "'$1'",
	"client_id": "'$2'",
	"client_secret": "'$3'",
	"grant_type": "refresh_token"
}' \
-X POST \
-v https://www.googleapis.com/oauth2/v4/token \
| \
jq -r '.access_token'`

if [[ "$(printf '%s' "$token")" == '' ]]
then
  echo "Action failed during authorisation"
  exit 1
else
  echo "Authorisation is successful, token: $token"
fi

uploadResult=`curl \
--silent \
--show-error \
--fail \
-H "Authorization: Bearer $token" \
-H "x-goog-api-version: 2" \
-X PUT \
-T $4 \
-v https://www.googleapis.com/upload/chromewebstore/v1.1/items/$5`

echo "Uload result: $uploadResult"

status=`echo $uploadResult | jq -r '.uploadState'`

echo "Uload status: $status"

if [[ $status == 'FAILURE' ]]
then
  echo "Action failed while uploading the build"
  exit 1
fi

if [ $6 == true ] #publish
then
  publishResult=`curl \
  --silent \
  --show-error \
  --fail \
  -H "Authorization: Bearer $token" \
  -H "x-goog-api-version: 2" \
  -X POST \
  -T $4 \
  -v https://www.googleapis.com/upload/chromewebstore/v1.1/items/$5/publish \
  -d publishTarget=default`
  
  echo "Publish result: $publishResult"

  publish=`echo $publishResult | jq -r '.publishState'`

  echo "Publish status: $publish"

  if [[ $publish == 'FAILURE' ]]
  then
    echo "Action failed while publishing"
    exit 1
  fi
fi

echo "Upload is successful"
exit 0