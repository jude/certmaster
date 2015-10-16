# This is the test /etc/certmaster.conf file used with the certmaster bats tests

[main]
listen_addr = 
listen_port = 51235
cert_extension = cert
sync_certs = False
log_level = debug

# Use thse settings if no --ca flag provided
autosign = no
cadir = /etc/pki/certmaster/ca
cert_dir = /etc/pki/certmaster
certroot = /var/lib/certmaster/certmaster/certs
csrroot = /var/lib/certmaster/certmaster/csrs

# use these directories if '--ca=test' is provided in the certmaster-ca commands
[ca:test]
autosign = yes
cadir = /etc/pki/certmaster/test-ca
cert_dir = /etc/pki/certmaster/test
certroot = /var/lib/certmaster/test/certs
csrroot = /var/lib/certmaster/test/csrs

[ca:md5]
autosign = yes
cadir = /etc/pki/certmaster/md5-ca
cert_dir = /etc/pki/certmaster/md5
certroot = /var/lib/certmaster/md5/certs
csrroot = /var/lib/certmaster/md5/csrs
hash_function = md5

[ca:sha1]
autosign = yes
cadir = /etc/pki/certmaster/sha1-ca
cert_dir = /etc/pki/certmaster/sha1
certroot = /var/lib/certmaster/sha1/certs
csrroot = /var/lib/certmaster/sha1/csrs
hash_function = sha1

[ca:sha224]
autosign = yes
cadir = /etc/pki/certmaster/sha224-ca
cert_dir = /etc/pki/certmaster/sha224
certroot = /var/lib/certmaster/sha224/certs
csrroot = /var/lib/certmaster/sha224/csrs
hash_function = sha224

