#!/bin/sh
set -e

if [ -z $1 ]; then
# `cat << EOF` This means that cat should stop reading when EOF is detected
cat << EOF
Usage: ./installer -v <espo-version> [-hrV]
Create OAuth2 client in Hydra

-i    Client ID
-n    Client Name
-h    Hydra client endpoint (default https://hydra:4445/clients)
-s    Scopes (can be used multiple times)
-r    Redirect URIs (can be used multiple times)
-g    Grant Types (can be used multiple times)
-t    Response Types (can be used multiple times)
-u    Update if found
-a    Audience
-v    Verbose output

EOF
# EOF is found above and hence cat command stops reading. This is equivalent to echo but much neater when printing out.
  echo "help"
  exit 0
fi

# default hydra url (internal)
HYDRA_CLIENTS_URL="https://hydra:4445/clients"

# random secret
CLIENT_SECRET=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)

while getopts 'vua:t:g:s:i:n:h:r:' c
do
  case $c in
    i) CLIENT_ID=$OPTARG ;;
    n) CLIENT_NAME=$OPTARG ;;
    h) HYDRA_CLIENTS_URL=$OPTARG ;;
    u) UPDATE=true ;;
    v) VERBOSE=true ;;
    s) if [ -z $SCOPES ]; then
         SCOPES="$OPTARG"
       else
         SCOPES="$SCOPES $OPTARG"
       fi
       ;;
    r) if [ -z $REDIRECT_URIS ]; then
         REDIRECT_URIS="\"$OPTARG\""
       else
         REDIRECT_URIS="$REDIRECT_URIS,\"$OPTARG\""
       fi
       ;;
    a) if [ -z $AUDIENCE ]; then
         AUDIENCE="\"$OPTARG\""
       else
         AUDIENCE="$AUDIENCE,\"$OPTARG\""
       fi
       ;;
    g) if [ -z $GRANT_TYPES ]; then
         GRANT_TYPES="\"$OPTARG\""
       else
         GRANT_TYPES="$GRANT_TYPES,\"$OPTARG\""
       fi
       ;;
    t) if [ -z $RESPONSE_TYPES ]; then
         RESPONSE_TYPES="\"$OPTARG\""
       else
         RESPONSE_TYPES="$RESPONSE_TYPES,\"$OPTARG\""
       fi
       ;;
  esac
done


ERR=false
if [ -z $CLIENT_ID ]; then
  echo "client_id required (-i)"
  ERR=true
fi

if [ -z $CLIENT_NAME ]; then
  echo "client_name required (-n)"
  ERR=true
fi

if [ "$ERR" = true ]; then
  echo "Errors found, exiting"
  exit 1
fi

# check if already exists
RETURN_CODE=$(curl -s -o /dev/null -w "%{http_code}" -k -I -X GET "$HYDRA_CLIENTS_URL/$CLIENT_ID")

PAYLOAD='{"client_id": "'"$CLIENT_ID"'", "client_name": "'"$CLIENT_NAME"'", "client_secret": "'"$CLIENT_SECRET"'", "redirect_uris": ['"$REDIRECT_URIS"'], "audience": ['"$AUDIENCE"'], "scope": "'"$SCOPES"'", "grant_types": ['"$GRANT_TYPES"'], "response_types": ['"$RESPONSE_TYPES"']}'

if [ "$RETURN_CODE" = "200" ]; then

  if [ "$UPDATE" != true ]; then
    echo "Client already exists with ID $CLIENT_ID and -u not provided"
    exit 0
  fi

  RESPONSE=$(curl -k -X PUT -d "$PAYLOAD" $HYDRA_CLIENTS_URL/$CLIENT_ID)
else
  # Create client credentials for service
  RESPONSE=$(curl -k -X POST -d "$PAYLOAD" $HYDRA_CLIENTS_URL)
fi

if [ "$VERBOSE" = true ]; then
  echo "Request:"
  echo $PAYLOAD
  echo "Response:"
  echo $RESPONSE
fi

echo -n $CLIENT_SECRET
