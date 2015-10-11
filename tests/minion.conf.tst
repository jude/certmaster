# configuration for minions

[main]
#certmaster = certmaster
certmaster = localhost
certmaster_port = 51235
log_level = DEBUG
cert_dir = /etc/pki/certmaster

[ca:test]
cert_dir = /etc/pki/certmaster-test
hash_function = sha256

[ca:sha1]
cert_dir = /etc/pki/certmaster-sha1
hash_function = sha1

[ca:sha224]
cert_dir = /etc/pki/certmaster-sha224
hash_function = sha224

