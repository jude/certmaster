# configuration for minions

[main]
#certmaster = certmaster
certmaster = localhost
certmaster_port = 51235
log_level = DEBUG
cert_dir = /etc/pki/certmaster

# [ca:ldap]
# cert_dir = /etc/pki/certmaster-ldap

[ca:test]
cert_dir = /etc/pki/certmaster-test

