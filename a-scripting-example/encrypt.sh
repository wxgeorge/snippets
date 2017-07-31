#!/bin/bash

# Helper to encrypt data.
# Obverse of decrypt.rb, referenced herein.

some_random_bytes() {
  dd if=/dev/random bs=16 count=1 2>/dev/null | hexdump -e '16/1 "%02x" ""'
}

main() {
  FILE=$1

  # encryption requires both key and iv.
  # Security of the encrypted data depends on these being drawn from a high entropy distribution.
  # Sufficiently paranoid users should not trust /dev/random;
  # this implementation is provided for illustration and testing.
  [[ $2 != "" ]] && KEY=$2         || KEY=$(some_random_bytes)
  [[ $2 != "" ]] && unset SHOW_KEY || SHOW_KEY="true"

  [[ $3 != "" ]] && IV=$3          || IV=$(some_random_bytes)
  [[ $3 != "" ]] && unset SHOW_IV  || SHOW_IV="true"

  openssl enc -aes-128-cbc -in $FILE -out $FILE.enc -K $KEY -iv $IV

  if [[ "$SHOW_KEY" != "" ]]; then echo "Key='$KEY'"; fi
  if [[ "$SHOW_IV"  != "" ]]; then echo "IV='$IV'"  ; fi

  # sanity check
  env KEY=$KEY IV=$IV ruby decrypt.rb $FILE.enc
  diff $FILE $FILE.enc.dec
  if [[ $? != 0 ]]; then
    echo "Error: round-trip of encryption failed."
    return 1
  fi
  rm $FILE.enc.dec
}

main "$@"
