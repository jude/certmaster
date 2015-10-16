VERSION		= 0.29
RELEASE		= 1
PYTHON		= /usr/bin/python
DIST            = pwan

MESSAGESPOT=po/messages.pot

TOPDIR = $(shell pwd)
DIRS	= certmaster docs scripts
PYDIRS	= certmaster scripts
EXAMPLEDIR = examples
INITDIR	= init-scripts

all: rpms

versionfile:
	echo "version:" $(VERSION) > etc/version
	echo "release:" $(RELEASE) >> etc/version
	echo "source build date:" $(DATE) >> etc/version
	echo "git commit:" $(shell git log -n 1 --pretty="format:%H") >> etc/version
	echo "git date:" $(shell git log -n 1 --pretty="format:%cd") >> etc/version

manpage:
	pod2man --center="certmaster-request" --release="" ./docs/certmaster-request.pod | gzip -c > ./docs/certmaster-request.1.gz
	pod2man --center="certmaster" --release="" ./docs/certmaster.pod | gzip -c > ./docs/certmaster.1.gz
	pod2man --center="certmaster-ca" --release="" ./docs/certmaster-ca.pod | gzip -c > ./docs/certmaster-ca.1.gz
	pod2man --center="certmaster-sync" --release="" ./docs/certmaster-sync.pod | gzip -c > ./docs/certmaster-sync.1.gz

messages: certmaster/*.py
	touch $(MESSAGESPOT)
	xgettext -k_ -kN_ -o $(MESSAGESPOT) certmaster/*.py
	sed -i'~' -e 's/SOME DESCRIPTIVE TITLE/certmaster/g' -e 's/YEAR THE PACKAGE'"'"'S COPYRIGHT HOLDER/2007 Red Hat, inc. /g' -e 's/FIRST AUTHOR <EMAIL@ADDRESS>, YEAR/Adrian Likins <alikins@redhat.com>, 2007/g' -e 's/PACKAGE VERSION/certmaster $(VERSION)-$(RELEASE)/g' -e 's/PACKAGE/certmaster/g' $(MESSAGESPOT)

build: clean
	$(PYTHON) setup.py build -f

clean:
	-rm -f  MANIFEST
	-rm -rf dist/ build/
	-rm -rf *~
	-rm -rf rpm-build/
	-rm -rf docs/*.gz
	-for d in $(DIRS); do ($(MAKE) -C $$d clean ); done

clean_hard:
	-rm -rf $(shell $(PYTHON) -c "from distutils.sysconfig import get_python_lib; print get_python_lib()")/certmaster 

clean_harder:
	-rm -rf /etc/pki/certmaster
	-rm -rf /etc/certmaster
	-rm -rf /var/lib/certmaster

clean_hardest: clean_rpms


install: build manpage
	$(PYTHON) setup.py install -f

install_hard: clean_hard install

install_harder: clean_harder install

install_hardest: clean_harder clean_rpms rpms install_rpm restart

install_rpm:
	-rpm -Uvh rpm-build/certmaster-$(VERSION)-$(RELEASE)$(shell rpm -E "%{?dist}").noarch.rpm

restart:
	-/etc/init.d/certmaster restart

recombuild: install_harder restart

clean_rpms:
	-rpm -e certmaster

sdist: messages
	$(PYTHON) setup.py sdist

new-rpms: bumprelease rpms

pychecker:
	-for d in $(PYDIRS); do ($(MAKE) -C $$d pychecker ); done   
pyflakes:
	-for d in $(PYDIRS); do ($(MAKE) -C $$d pyflakes ); done	

money: clean
	-sloccount --addlang "makefile" $(TOPDIR) $(PYDIRS) $(EXAMPLEDIR) $(INITDIR) 

async: install
	/sbin/service certmaster restart
	sleep 4

rpms: build manpage sdist
	mkdir -p rpm-build
	cp dist/*.gz rpm-build/
	echo ${RELEASE}
	rpmbuild --define "_topdir %(pwd)/rpm-build" \
        --define "dist ${DIST}" \
	--define "_builddir %{_topdir}" \
	--define "_rpmdir %{_topdir}" \
	--define "_srcrpmdir %{_topdir}" \
	--define '_rpmfilename %%{NAME}-%%{VERSION}-%%{RELEASE}.%%{ARCH}.rpm' \
	--define "_specdir %{_topdir}" \
	--define "_sourcedir  %{_topdir}" \
	-ba certmaster.spec
