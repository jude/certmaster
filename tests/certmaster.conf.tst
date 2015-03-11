# This is the test /etc/certmaster.conf file used with the certmaster bats tests

[main]
listen_addr = 
listen_port = 51235
cert_extension = cert
sync_certs = False

# Use thse settings if no --ca flag provided
autosign = no
cadir = /etc/pki/certmaster/ca
cert_dir = /etc/pki/certmaster
certroot = /var/lib/certmaster/certmaster/certs
csrroot = /var/lib/certmaster/certmaster/csrs

# use these directories if '--ca=yourapp' provided in the certmaster-ca commands
[ca:test]
autosign = yes
cadir = /etc/pki/certmaster/test-ca
cert_dir = /etc/pki/certmaster/test
certroot = /var/lib/certmaster/test/certs
csrroot = /var/lib/certmaster/test/csrs

