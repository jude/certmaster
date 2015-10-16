#!/bin/bash
# shunit2 tests for certmaster
# (sorry bats, but I couldn't figure out how to push a command into the background with ya)

setUp() 
{
    /etc/init.d/certmaster stop >& /dev/null || true
    mkdir -p /etc/certmaster
    cp certmaster.conf.tst /etc/certmaster/certmaster.conf
    cp minion.conf.tst /etc/certmaster/minion.conf
    rm -rf /var/lib/certmaster
    rm -rf /var/lib/certmaster/test
    rm -rf /var/lib/certmaster/md5
    rm -rf /var/lib/certmaster/sha1
    rm -rf /var/lib/certmaster/sha224
    rm -rf /etc/pki/certmaster
    rm -rf /etc/pki/certmaster-test
    rm -rf /etc/pki/certmaster-md5
    rm -rf /etc/pki/certmaster-sha1
    rm -rf /etc/pki/certmaster-sha224
    /etc/init.d/certmaster start  >& /dev/null
}

tearDown() {
    /etc/init.d/certmaster stop >& /dev/null
}

test_CertmasterCaAvailable()
{
    [[ -x "/usr/bin/certmaster-ca" ]]
    assertTrue "certmaster-ca exists" $?
}

test_CertmasterRequestAvailable()
{
    [[ -x "/usr/bin/certmaster-request" ]]
    assertTrue "certmaster-request exists" $?
}

test_CertmasterDaemonRunning()
{
    /etc/init.d/certmaster status
    assertTrue "certmaster daemon running" $?
}

test_CertmasterRequestHelp()
{
    actual=`certmaster-request --help`

    expected=$(cat <<EOF
Usage: certmaster-request [options]

Options:
  -h, --help       show this help message and exit
  --hostname=NAME  hostname to use as the CN for the certificate
  --ca=CA          certificate authority used to sign the certificate
EOF
)

   assertEquals "certmaster-request --help" "$actual" "$expected"

}

test_CertmasterRequestHFlag() 
{
    actual=`certmaster-request -h`

    expected=$(cat <<EOF
Usage: certmaster-request [options]

Options:
  -h, --help       show this help message and exit
  --hostname=NAME  hostname to use as the CN for the certificate
  --ca=CA          certificate authority used to sign the certificate
EOF
)
   assertEquals "certmaster-request -h" "$actual" "$expected"

}

test_CertmasterRequestBadFlag()
{

    # backticks don't capture stderr...
    actual=$(certmaster-request --blah 2>&1)

    expected=$(cat <<EOF
Usage: certmaster-request [options]

certmaster-request: error: no such option: --blah
EOF
)
   assertEquals "certmaster-request --blah" "$actual" "$expected"

}

test_CertmasterRequest_UnknownCA()
{
    actual=$(certmaster-request --hostname unknown.pwan.co --ca unknown 2>&1)
    expected=$(cat <<EOF
error: Unknown cert authority: unknown
EOF
)

   assertEquals "certmaster-request --ca unknown" "$actual" "$expected"
}

test_CertmasterCAHelp()
{
    actual=`certmaster-ca --help`
    expected=$(cat <<EOF
Usage: certmaster-ca <option> [args]

Options:
  --version         show program's version number and exit
  -h, --help        show this help message and exit
  --ca=CA           certificate authority used to sign/list certs
  -l, --list        list signing requests remaining
  -s, --sign        sign requests of hosts specified
  -c, --clean       clean out all certs or csrs for the hosts specified
  --list-signed     list all signed certs
  --list-cert-hash  list the cert hash for signed certs
EOF
)
   assertEquals "certmaster-ca --help" "$actual" "$expected"
}

test_CertmasterCAHFlag()
{
    actual=`certmaster-ca -h`
    expected=$(cat <<EOF
Usage: certmaster-ca <option> [args]

Options:
  --version         show program's version number and exit
  -h, --help        show this help message and exit
  --ca=CA           certificate authority used to sign/list certs
  -l, --list        list signing requests remaining
  -s, --sign        sign requests of hosts specified
  -c, --clean       clean out all certs or csrs for the hosts specified
  --list-signed     list all signed certs
  --list-cert-hash  list the cert hash for signed certs
EOF
)
   assertEquals "certmaster-ca -h" "$actual" "$expected"
}

test_CertmasterCAVersion()
{
    actual=`certmaster-ca --version`

    [[ "$actual" == *"version:"* ]]    
    assertTrue "version includes a version" $?

    [[ "$actual" == *"release:"* ]]    
    assertTrue "version includes a release" $?
}

test_CertmasterCA_UnknownCA()
{
    actual=$(certmaster-ca --list --ca unknown 2>&1)

    expected=$(cat <<EOF
Unknown ca unknown: check /etc/certmaster.cfg
EOF
)

    assertEquals "certmaster-ca --ca unknown" "$actual" "$expected"
}

test_TestCA_Autosigning()
{
    certmaster-request --hostname testcert.pwan.co --ca test

    [[ -e /etc/pki/certmaster-test ]]
    assertTrue "/etc/pki/certmaster-test exists" $?
    [[ -e /etc/pki/certmaster-test/testcert.pwan.co.cert ]]
    assertTrue "testcert.pwan.co.cert exists" $?
    [[ -e  /etc/pki/certmaster-test/testcert.pwan.co.pem ]]
    assertTrue "testcert.pwan.co.pem exists" $?
    [[ -e /etc/pki/certmaster-test/testcert.pwan.co.csr ]]
    assertTrue "testcert.pwan.co.csr exists" $?

    subject=`openssl x509 -in /etc/pki/certmaster-test/testcert.pwan.co.cert -subject -noout`
    [[ $subject == *"CN=testcert.pwan.co"* ]]

    openssl x509 -in /etc/pki/certmaster-test/testcert.pwan.co.cert  -text | grep Signature | grep sha256 > /dev/null 2>&1
    assertTrue "testcert.pwan.co.cert has a sha256 hash" $?

    openssl rsa -in /etc/pki/certmaster-test/testcert.pwan.co.pem -check > /dev/null 2>&1
    assertTrue "test.pwan.co.pem OK" $?
    openssl req -text -noout -verify -in /etc/pki/certmaster-test/testcert.pwan.co.csr > /dev/null 2>&1
    assertTrue "test.pwan.co.csr OK" $?

    # Verify there are no certs left to sign
    output=`certmaster-ca --list --ca test`
    assertEquals "nothing to sign" "$output" "No certificates to sign"

    # Verify the cert shows up in the signed list
    output=`certmaster-ca --list-signed --ca test`
    [[ $output == *"testcert.pwan.co"* ]]
    assertTrue "--list-signed includes testcert" $?

    # Verify the cert shows up in the list-cert-hash command
    output=`certmaster-ca --list-cert-hash --ca test`
    [[ $output == *"testcert.pwan.co"* ]]
    assertTrue "--list-cert-hash includes testcert" $?

}

test_MD5CA_Attempt() {

    # TODO:  Verify attempts to create MD5 certs fail
    actual=$(certmaster-request --hostname badmd5req.pwan.co --ca md5 2>&1)
    expected=$(cat <<EOF
error: md5 hash function is unsupported: md5
EOF
)
   assertEquals "MD5CA Attempt" "$actual" "$expected"
}

test_Sha1CA_Autosigning() {

    actual=$(certmaster-request --hostname testcert.pwan.co --ca sha1 2>&1)
    expected=$(cat <<EOF
Deprecated hash function of sha1: sha1
EOF
)
    assertEquals "deprecated sha1 warning" "$actual" "$expected"
    openssl x509 -in /etc/pki/certmaster-sha1/testcert.pwan.co.cert  -text | grep Signature | grep sha1 > /dev/null 2>&1
    assertTrue "testcert.pwan.co.cert has a sha1 hash" $?

}

test_Sha224CA_Autosigning() {

    # TODO:  Verify /etc/pki/certmaster-test/testcert.pwan.co.cert is using sha224
    certmaster-request --hostname testcert.pwan.co --ca sha224
    openssl x509 -in /etc/pki/certmaster-sha224/testcert.pwan.co.cert  -text | grep Signature | grep sha224 > /dev/null 2>&1
    assertTrue "testcert.pwan.co.cert has a sha224 hash" $?

}

test_DefaultCA_NonAutosigning() {

    # Turn on job control, so 'fg' is available
    set -m 

    # Request a cert
    certmaster-request --hostname defaultcert.pwan.co &
    sleep 1
    echo "...patience grasshopper..."

    # Verify the cert is waiting to be signed
    output=`certmaster-ca --list`
    [[ $output == *"defaultcert.pwan.co"* ]]
    assertTrue "$output includes defaultcert" $?

    # Sign the cert
    output=`certmaster-ca --sign defaultcert.pwan.co`
    sleep 1

    # Bring the request back to the foreground so it can finish
    fg 

    # Verify there are no certs left to sign
    output=`certmaster-ca --list`
    assertEquals "nothing to sign" "$output" "No certificates to sign"

    # Verify the cert shows up in the signed list
    output=`certmaster-ca --list-signed`
    [[ $output == *"defaultcert.pwan.co"* ]]
    assertTrue "--list-signed includes defaultcert" $?

    # Verify the cert shows up in the list-cert-hash command
    output=`certmaster-ca --list-cert-hash`
    [[ $output == *"defaultcert.pwan.co"* ]]
    assertTrue "--list-cert-hash includes defaultcert" $?

    # Verify all the expected files exist
    [[ -e /etc/pki/certmaster ]]
    assertTrue "/etc/pki/certmaster exists" $?
    [[ -e  /etc/pki/certmaster/defaultcert.pwan.co.cert ]]
    assertTrue "defaultcert.pwan.co.cert.exists" $?
    [[ -e /etc/pki/certmaster/defaultcert.pwan.co.pem ]]
    assertTrue "defaultcert.pwan.co.pem exists" $?
    [[ -e /etc/pki/certmaster/defaultcert.pwan.co.csr ]]
    assertTrue "default.pwan.co.csr exists" $?

    # Verify the cert's CN
    subject=`openssl x509 -in /etc/pki/certmaster/defaultcert.pwan.co.cert -subject -noout`
    [[ $subject == *"CN=defaultcert.pwan.co"* ]]

    # Verify the key and signing request are valid
    openssl rsa -in /etc/pki/certmaster/defaultcert.pwan.co.pem -check > /dev/null 2>&1
    assertTrue "default.pwan.co.pem OK" $?
    openssl req -text -noout -verify -in /etc/pki/certmaster/defaultcert.pwan.co.csr > /dev/nulla 2>&1
    assertTrue "defaultcert.pwan.co.csr OK" $?

    set +m
}


# load shunit2
. /usr/share/shunit2/shunit2
