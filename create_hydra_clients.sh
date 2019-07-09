#!/bin/bash

INPUT=$(cat -)

OUTDIR="/output"

mkdir -p $OUTDIR

for row in $(printf "$INPUT" | jq -c '.[]'); do
  _jq() {
    echo ${1} | jq -r ${2}
  }

  HYDRA_HOST=$(_jq "$row" '.hydra_host')
  HYDRA_CLIENTS_URL=$HYDRA_HOST/clients
  CLIENT_ID=$(_jq "$row" '.client_id')
  CLIENT_NAME=$(_jq "$row" '.client_name')
  SCOPES=$(_jq "$row" '.scopes')
  REDIRECT_URIS=$(_jq "$row" '.redirect_uris')
  AUDIENCE=$(_jq "$row" '.audience')
  GRANT_TYPES=$(_jq "$row" '.grant_types')
  RESPONSE_TYPES=$(_jq "$row" '.response_types')
  UPDATE=$(_jq "$row" '.update_if_exists')
  VERBOSE=$(_jq "$row" '.verbose')
  OUTPUT_DIR=$(_jq "$row" '.output_dir')
  OUTPUT_FILE=$(_jq "$row" '.output_file')
  OUTPUT_LINES=$(_jq "$row" '.output_lines')
  CLIENT_SECRET=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)

  mkdir -p $OUTDIR/$OUTPUT_DIR

  SCOPES_JSON=""
  for value in $(_jq "$SCOPES" '.[]'); do
    if [ -z "$SCOPES_JSON" ]; then
      SCOPES_JSON="$value"
    else
      SCOPES_JSON="$SCOPES_JSON $value"
    fi
  done

  REDIRECT_URIS_JSON=""
  for value in $(_jq "$REDIRECT_URIS" '.[]'); do
    if [ -z "$REDIRECT_URIS_JSON" ]; then
      REDIRECT_URIS_JSON="\"$value\""
    else
      REDIRECT_URIS_JSON="$REDIRECT_URIS_JSON,\"$value\""
    fi
  done

  AUDIENCE_JSON=""
  for value in $(_jq "$AUDIENCE" '.[]'); do
    if [ -z "$AUDIENCE_JSON" ]; then
      AUDIENCE_JSON="\"$value\""
    else
      AUDIENCE_JSON="$AUDIENCE_JSON,\"$value\""
    fi
  done

  GRANT_TYPES_JSON=""
  for value in $(_jq "$GRANT_TYPES" '.[]'); do
    if [ -z "$GRANT_TYPES_JSON" ]; then
      GRANT_TYPES_JSON="\"$value\""
    else
      GRANT_TYPES_JSON="$GRANT_TYPES_JSON,\"$value\""
    fi
  done

  RESPONSE_TYPES_JSON=""
  for value in $(_jq "$RESPONSE_TYPES" '.[]'); do
    if [ -z "$RESPONSE_TYPES_JSON" ]; then
      RESPONSE_TYPES_JSON="\"$value\""
    else
      RESPONSE_TYPES_JSON="$RESPONSE_TYPES_JSON,\"$value\""
    fi
  done

  ERR=false
  if [ -z $CLIENT_ID ]; then
    printf "client_id required\n" >&2
    ERR=true
  fi

  if [ -z $CLIENT_NAME ]; then
    printf "client_name required\n" >&2
    ERR=true
  fi

  if [ "$ERR" = true ]; then
    printf "Errors found, exiting\n" >&2
    exit 1
  fi



  # check if already exists
  RETURN_CODE=$(curl -s -o /dev/null -w "%{http_code}" -k -I -X GET "$HYDRA_CLIENTS_URL/$CLIENT_ID")

  PAYLOAD='{"client_id": "'"$CLIENT_ID"'", "client_name": "'"$CLIENT_NAME"'", "client_secret": "'"$CLIENT_SECRET"'", "redirect_uris": ['"$REDIRECT_URIS_JSON"'], "audience": ['"$AUDIENCE_JSON"'], "scope": "'"$SCOPES_JSON"'", "grant_types": ['"$GRANT_TYPES_JSON"'], "response_types": ['"$RESPONSE_TYPES_JSON"']}'

  if [ "$VERBOSE" = true ]; then
    printf "\n\nRequest logging started\n" >&2
  fi

  RESPONSE=""
  if [ "$RETURN_CODE" = "200" ]; then

    if [ "$UPDATE" != true ]; then
      printf "Client already exists with ID $CLIENT_ID and update_if_exists not true\n" >&2
      continue
    fi

    URL=$HYDRA_CLIENTS_URL/$CLIENT_ID

    if [ "$VERBOSE" = true ]; then
      printf "Request:\n" >&2
      printf "PUT $URL\n"
      printf "Body: $PAYLOAD\n" >&2
    fi

    RESPONSE=$(curl -k -X PUT -d "$PAYLOAD" $URL)
  else
    URL=$HYDRA_CLIENTS_URL

    if [ "$VERBOSE" = true ]; then
      printf "Request:\n" >&2
      printf "POST $URL\n"
      printf "Body: $PAYLOAD\n" >&2
    fi

    # Create client credentials for service
    RESPONSE=$(curl -k -X POST -d "$PAYLOAD" $HYDRA_CLIENTS_URL)
  fi

  if [ "$VERBOSE" = true ]; then
    printf "Response:\n" >&2
    printf "$RESPONSE\n" >&2
    printf "Request logging ended\n\n" >&2
  fi

  for line in $(printf "$row" | jq -c '.output_lines[]'); do
    LINE=$(_jq "$line" '.line')
    VALUE_FIELD=$(_jq "$line" '.value')
    VALUE=$(jq -r $VALUE_FIELD <<< "$RESPONSE")
    printf $VALUE >&2
    PRINT_LINE="$LINE$VALUE"

    echo "$PRINT_LINE" >> $OUTDIR/$OUTPUT_DIR/$OUTPUT_FILE
  done

done
