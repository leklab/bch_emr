#!/bin/bash
#
# htslib is required for samtools
# develop is the default branch for the htslib repo
#

set -xe

REPOSITORY_URL="https://github.com/samtools/htslib.git"

dnf install -y autoconf automake

if [ -z "$HTSLIB_VERSION" ]; then
    HTSLIB_VERSION="develop";
    echo "HTSLIB_VERSION was empty.  Setting to develop."
fi

mkdir -p /opt
cd /opt
git clone "$REPOSITORY_URL"
cd htslib
git checkout "$HTSLIB_VERSION"

git submodule update --init --recursive

autoreconf -i
./configure
make -j "$(grep -c ^processor /proc/cpuinfo)"
make install

# htslib source is not removed as it's used during the VEP build
