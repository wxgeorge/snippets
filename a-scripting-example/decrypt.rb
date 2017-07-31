#!/usr/bin/env ruby

# example of undoing encryption applied in helpers.sh
require 'openssl'


path = ARGV[0]

# key and iv come in as a hexstring. We need this as a binary string
key = ENV["KEY"].scan(/../).map(&:hex).map(&:chr).join("")
iv  = ENV["IV" ].scan(/../).map(&:hex).map(&:chr).join("")

decipher = OpenSSL::Cipher::AES.new(128, :CBC)
decipher.decrypt
decipher.key = key
decipher.iv  = iv

encrypted = File.open(path, "r").read
decrypted = decipher.update(encrypted) + decipher.final

f = File.open("#{path}.dec", "w")
f.write decrypted
f.close
