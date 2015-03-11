#!/usr/bin/env bats

setup() {
    /etc/init.d/certmaster stop || true
    mkdir -p /etc/certmaster
    cp certmaster.conf.tst /etc/certmaster/certmaster.conf
    cp minion.conf.tst /etc/certmaster/minion.conf
    rm -rf /var/lib/certmaster/certmaster
    rm -rf /var/lib/certmaster/test
    rm -rf /etc/pki/certmaster
    rm -rf /etc/pki/certmaster-test
    /etc/init.d/certmaster start
}

teardown() {
    /etc/init.d/certmaster stop
}

@test "check that certmaster-ca is availabe" {
    command -v certmaster-ca
}

@test "check that certmaster-request is available" {
    command -v certmaster-request
}

@test "check that the certmaster daemon is running" {
    /etc/init.d/certmaster status
}

@test "check certmaster-request --help" {
    run certmaster-request --help

    expected=$(cat <<EOF
Usage: certmaster-request [options]

Options:
  -h, --help       show this help message and exit
  --hostname=NAME  hostname to use as the CN for the certificate
  --ca=CA          certificate authority used to sign the certificate
EOF
)
    [ "$output" = "$expected" ]

}

@test "check certmaster-request -h" {
    run certmaster-request -h

    expected=$(cat <<EOF
Usage: certmaster-request [options]

Options:
  -h, --help       show this help message and exit
  --hostname=NAME  hostname to use as the CN for the certificate
  --ca=CA          certificate authority used to sign the certificate
EOF
)
    [ "$output" = "$expected" ]

}

@test "check certmaster-request --blah" {

    run certmaster-request --blah

    expected=$(cat << EOF
Usage: certmaster-request [options]

certmaster-request: error: no such option: --blah
EOF
)

}

@test "signing a cert with the autosigning test ca" {
    run certmaster-request --hostname testcert.pwan.co --ca test

    stat /etc/pki/certmaster-test
    stat /etc/pki/certmaster-test/testcert.pwan.co.cert
    stat /etc/pki/certmaster-test/testcert.pwan.co.pem
    stat /etc/pki/certmaster-test/testcert.pwan.co.csr

    subject=`openssl x509 -in /etc/pki/certmaster-test/testcert.pwan.co.cert -subject -noout`
    [[ $subject == *"CN=testcert.pwan.co"*  ]]

    openssl rsa -in /etc/pki/certmaster-test/testcert.pwan.co.pem -check
    openssl req -text -noout -verify -in /etc/pki/certmaster-test/testcert.pwan.co.csr
}

@test "signing a cert with the non-autosigning default ca" {

    setsid certmaster-request --hostname defaultcert.pwan.co

    echo "hello" > blah.txt
    output=`certmaster-ca --list`
    echo "$output" >> blah.txt
    [[ $output == *"defaultcert.pwan.co"* ]]

    run certmaster-ca --sign defaultcert.pwan.co

    stat /etc/pki/certmaster
    stat /etc/pki/certmaster/defaultcert,pwan.co.cert
    stat /etc/pki/certmaster/defaultcert,pwan.co.pem
    stat /etc/pki/certmaster/defaultcert,pwan.co.csr

    subject=`openssl x509 -in /etc/pki/certmaster/defaultcert.pwan.co.cert -subject -noout`
    [[ $subject == *"CN=defaultcert.pwan.co"*  ]]

    openssl rsa -in /etc/pki/certmaster/defaultcert.pwan.co.pem -check
    openssl req -text -noout -verify -in /etc/pki/certmaster/defaultcert.pwan.co.csr

}
