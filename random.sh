#!/bin/bash

INPUT=$(cat -)

OUTDIR="/output"

mkdir -p $OUTDIR

for row in $(printf "$INPUT" | jq -c '.[]'); do
  _jq() {
    echo ${1} | jq -r ${2}
  }

  VERBOSE=$(_jq "$row" '.verbose')
  OUTPUT_DIR=$(_jq "$row" '.output_dir')
  OUTPUT_FILE=$(_jq "$row" '.output_file')
  OUTPUT_LINES=$(_jq "$row" '.output_lines')

  mkdir -p $OUTDIR/$OUTPUT_DIR

  ERR=false
  if [ "$ERR" = true ]; then
    printf "Errors found, exiting\n" >&2
    exit 1
  fi

  for line in $(printf "$row" | jq -c '.output_lines[]'); do
    LINE=$(_jq "$line" '.line')
    VALUE=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
    PRINT_LINE="$LINE$VALUE"

    echo "$PRINT_LINE" >> $OUTDIR/$OUTPUT_DIR/$OUTPUT_FILE
  done

done
