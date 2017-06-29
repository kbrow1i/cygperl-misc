#! /bin/bash

dirs="perl-*"

for d in ${dirs}
do
    eval $(grep '^RELEASE=' ${d}/${d}.cygport)
    ((RELEASE++))
    sed -i -e "s/^RELEASE=.*/RELEASE=$RELEASE/" ${d}/${d}.cygport
done
