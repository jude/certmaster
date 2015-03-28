_certmaster -- it hands out SSL certs!_
  
read more at:

[Fedora Project Page](https://fedorahosted.org/certmaster/)

[Fedora Repo](http://git.fedorahosted.org/git/?p=certmaster.git;a=summary)

---

## About this fork

### Multiple CA support

This certmaster fork introduces a new '--ca' argument for specifying an alternative certificate authority.

This allows one certmaste instance to supply certs from multiple authorities instead of having to have a 
separate certmaster instance for each certificate authority might be using.

If you don't want to use multiple CA's, this fork should act just like the parent certmaster project - you
should be able to upgrade your existing certmaster to this version, and it will continue to server your existing certs

If you want to add an additional certificate authorities, add a section to your certmaster.conf file as per below 
for each CA, using a different name and set of directories for each CA.

    [ca:name]
    autosign = yes_or_no
    cadir = /path/to/cadir
    cert_dir = /path/to/cert_dir
    certroot = /path/to/certroot
    csrroot = /path/to/csrroot

Then to use the new CA, include the argument '--ca=name' in your list of certmaster-ca arguments to use the 'name' CA.

Likewise, when requesting certs from the new CA, include a section of the following form in your minion.conf file:

    [ca:name]
    cert_dir = /path/to/cert_dir

Then include the argument '--ca=name' in your certmaster-request commands to request a cert from the 'name' CA.

If the '--ca' argument is not given in the certmaster-ca or certmaster-request commands, then the original 
autosign, cadir, cert_dir, certroot, and csrroot options from the main section of certmaster.conf / minion.conf are used instead.

### Misc Changes
+ 'certmaster-ca --version' reads /etc/certmaste/version instead of func's version file
+ certmaster-sync doesn't error out if func if not present

