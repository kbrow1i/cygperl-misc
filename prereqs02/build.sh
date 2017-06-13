#! /bin/bash

# Run in elevated shell as kbrown-admin.
# Copy setup-*.exe to *.exe to avoid prompt.

SYSARCH=$(uname -m)
if [ ${SYSARCH} = i686 ]
then
    GENINI="GEN-ini"
    DEST_ARCH="x86"
else
    GENINI="GEN-ini64"
    DEST_ARCH="x86_64"
fi

setup="/c/downloads/cygwin/${DEST_ARCH}.exe"

GENINI() {
    mksetupini --arch=${DEST_ARCH} --release=kbrown --inifile=${DEST_ARCH}/setup.ini \
	       --okmissing=required-package --okmissing=curr --releasearea .
cd ${DEST_ARCH}
xz -c setup.ini > setup.xz
chown kbrown setup.ini setup.xz
cd ..
}

install() {
    local command
    pushd /c/downloads/cygwin/myrepo
    GENINI
    popd
    command="${setup} -q -X -L"
    for m in ${mods}
    do
	command+=" -P ${m}"
    done
    echo "Running ${command}"
    ${command}
}

mods="
         perl-MailTools
         perl-MIME-Charset
         perl-Authen-SASL
"

rm -f build_failures.txt test_failures.txt
touch build_failures.txt test_failures.txt
chown kbrown build_failures.txt test_failures.txt

export cygport_no_error=1

for m in ${mods}
do
    eval $(grep '^NAME=' ${m}/${m}.cygport)
    eval $(grep '^VERSION=' ${m}/${m}.cygport)
    eval $(grep '^RELEASE=' ${m}/${m}.cygport)
    PVR=${NAME}-${VERSION}-${RELEASE}
    ARCH=${SYSARCH}
    eval $(grep '^ARCH=' ${m}/${m}.cygport)
    if [ ${ARCH} = i686 -o ${SYSARCH} = x86_64 ]
    then
	echo "Entering ${m}..."
	cd ${m} || exit 1
	echo "Running cygport..."
	rm -rf ${PVR}.${ARCH}
	if cygport ${m}.cygport fetch all
	then
	    cygport ${m}.cygport test || echo $m >> ../test_failures.txt
	    if [ ${ARCH} = noarch ]
	    then
		dest=/c/downloads/cygwin/myrepo/noarch/release/
	    else
		dest=/c/downloads/cygwin/myrepo/${DEST_ARCH}/release/
	    fi
	    chown -R kbrown .
	    rm -rf ${dest}/${m}
	    cp -alf ${PVR}.${ARCH}/dist/${m} ${dest}
	else
	    echo ${m} >> ../build_failures.txt
	    chown -R kbrown .
	fi
	echo "Leaving ${m}."
	cd ..
    fi
done
install
if [ -n "$(cat *.txt)" ]
then
    echo There were failures.
    exit 1
else
    exit 0
fi

