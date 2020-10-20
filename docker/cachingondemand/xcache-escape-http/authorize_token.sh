#!/bin/bash

IAM_DEVICE_CODE_CLIENT_ID=a729738f-93e8-4a5f-9d58-ad6e61e4a911
IAM_DEVICE_CODE_CLIENT_SECRET=ANxMr_X7Lzia3C5UJmnFkQgF68TqLQPApMHDosCNJWoquHzObzc1_9ALuP6GLpzlFJcghd2KUbM5htwSrQWvTDE

IAM_DEVICE_CODE_ENDPOINT=https://iam-escape.cloud.cnaf.infn.it/devicecode
IAM_TOKEN_ENDPOINT=https://iam-escape.cloud.cnaf.infn.it/token

response=$(mktemp)

echo $response 

IAM_DEVICE_CODE_CLIENT_SCOPES_1=${IAM_DEVICE_CODE_CLIENT_SCOPES_1:-"storage.write:/magic"}
IAM_DEVICE_CODE_CLIENT_SCOPES_2=${IAM_DEVICE_CODE_CLIENT_SCOPES_2:-"storage.read:/magic"}

curl -q -f -s -u ${IAM_DEVICE_CODE_CLIENT_ID}:${IAM_DEVICE_CODE_CLIENT_SECRET} \
  -d client_id=a729738f-93e8-4a5f-9d58-ad6e61e4a911 -d scope=\"${IAM_DEVICE_CODE_CLIENT_SCOPES_1}\" -d scope=\"${IAM_DEVICE_CODE_CLIENT_SCOPES_2}\" ${IAM_DEVICE_CODE_ENDPOINT} > ${response}

device_code=$(jq -r .device_code ${response})
user_code=$(jq -r .user_code ${response})
verification_uri=$(jq -r .verification_uri ${response})
verification_uri_complete=$(jq -r .verification_uri_complete ${response})
expires_in=$(jq -r .expires_in ${response})

echo "Please open the following URL in the browser:"
echo
echo ${verification_uri_complete}
echo
echo "and, after having been authenticated, enter the following code when requested:"
echo
echo ${user_code}
echo
echo "Note that the code above expires in ${expires_in} seconds..."
echo "Once you have correctly authenticated and authorized this device, this script can be restarted to obtain a token. "

while true; do

  while true; do
    echo
    echo "Proceed? [Y/N] (CTRL-c to abort)"
    read a
    [[ $a = "y" || $a = "Y" ]] && break
    [[ $a = "n" || $a = "N" ]] && exit 0
  done

 curl -q -L -s \
    -u ${IAM_DEVICE_CODE_CLIENT_ID}:${IAM_DEVICE_CODE_CLIENT_SECRET} \
    -d grant_type=urn:ietf:params:oauth:grant-type:device_code \
    -d device_code=${device_code} ${IAM_TOKEN_ENDPOINT} 2>&1 > ${response}

  if [ $? -ne 0 ]; then
    echo "Error contacting IAM"
    cat ${response}
    exit 1
  fi

  error=$(jq -r .error ${response})
  error_description=$(jq -r .error_description ${response})

  if [[ "${error}" != "null" ]]; then
    echo "The IAM returned the following error:"
    echo
    echo ${error} " " ${error_description}
    echo
    continue;
  fi

  access_token=$(jq -r .access_token ${response})
  refresh_token=$(jq -r .refresh_token ${response})
  scope=$(jq -r .scope ${response})
  expires_in=$(jq -r .expires_in ${response})

  echo $refresh_token > /tmp/refresh_token

  echo
  echo "An access token was issued, with the following scopes:"
  echo
  echo ${scope}
  echo
  echo "which expires in ${expires_in} seconds."
  echo
  echo "The following command will set it in the IAM_ACCESS_TOKEN env variable:"
  echo
  echo "export TOKEN=\"${access_token}\""
  echo
  echo "${response}"

  exit 0

done

