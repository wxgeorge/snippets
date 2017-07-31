#!/bin/bash
#
# update-me.sh
#
# This script splits a pkcs#12 encoded certificate and private key into
# the format expected in this folder (PEM encoded cert, aes-encrypted PEM encoded private key).
#
# Why store creds in this way?
#
# The PKCS#12 standard is a standard for archiving cryptographic materials,
# A common use case is distributing a certified public key along with its private key.
# PKCS#12 does provide a means of handling private keys - namely a passphrase may
# be associated with a file, and this passphrase determines an AES key used to
# encrypt the file's content.
#
# However PKCS#12 has a legacy mode, which uses non-standard key derivation functions.
# So if you receive a PKCS#12 encoded file, it may not be safe to store in public storage.
#
# The purpose of this script is to split such a file into files that may safely
# be put in public storage (as the sensitive parts of the file _are_ encrypted under
# AES).
#
# This script also demos the range of the openssl binary.
#

docs=$(cat <<EOF
Usage: update-me.sh <pcks 12 encoded cert>

The job of this script is to update the credentials stored in this folder.
I expect the name of a pcks12 encoded certificate on the command line.
I will write some output to the terminal; this output is needed to use the stored credentials.
EOF)

if [[ $# -eq 0 ]]; then
  echo "$docs" # quoting needed to preserve newlines
  exit 0
fi

PATH=.:$PATH # for encrypt.sh and decrypt.rb

# We'll need the passphrase a couple times; let's get it from the user ourselves.
echo -n "Enter certificate passphrase:"
read -s PASSPHRASE # -s for silent. Don't echo to terminal
echo "" # to terminate the line

my_temp_file=$(mktemp)

openssl pkcs12 -in $1 -noout -passin pass:$PASSPHRASE &> $my_temp_file
out=$?
if [[ ! $out -eq 0 ]]; then
  # clear actionable error messages, yo!
  cat <<EOD

  pkcs check failed for file named "$1".

  > openssl pkcs12 -in $1 -noout -passin pass:\$YOUR_PROVIDED_PASSPHRASE
  $(cat $my_temp_file)

  Please confirm your input file is in PKCS#12 format.

EOD
  exit $out
fi

p12_file=$1
# We've confirmed the file is indeed in pkcs#12 format.
# Let's split it into it's component parts - private key and cert

openssl pkcs12 -in $p12_file -nocerts         -out key.pem   -passin  pass:$PASSPHRASE \
                                                             -passout pass:$PASSPHRASE >> $my_temp_file # don't change the passphrase
openssl pkcs12 -in $p12_file -clcerts -nokeys -out cert.pem  -passin pass:$PASSPHRASE  >> $my_temp_file

# now let's encrypt the key.pem
# pkcs12 does provide provisions for encrypting the private key,
# however since these keys are generated by a third party,
# i.e. Wells,
# we don't know how they've been generated, and I can't confirm that
# they are indeed AES encrypted under a key PBKDF-derived from the passphrase,
# so we inject our own layer of encryption

encrypt.sh key.pem
# this will fail if the key was not encrypted succesfully

cat <<EOD
Key split is complete.
We've created cert.pem, and key.pem.enc from the input file $p12_file.
We've left the private key in plaintext (key.pem) for debugging.
Please delete this file!
EOD

# rm key.pem # don't save unencrypted key!
