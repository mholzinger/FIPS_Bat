#!/bin/bash

SSL_MAJOR=1.0
SSL_MINOR=1e
SSLVER=$SSL_MAJOR.$SSL_MINOR

FIPS_MAJOR=2.0
FIPS_MINOR=5
FIPSVER=$FIPS_MAJOR.$FIPS_MINOR

PROJ_MAIN=~/openssl-fips

check_err(){ error_state=$(echo $?)
if [[ "$error_state" != "0" ]];then
    echo $1
    exit
fi
}

# add test here for curl or wget - switch commands to necessary component

# clean up
rm -rf  $PROJ_MAIN/

# throw routine in to do a check to see if ssl dir exists
sudo rm -rf /usr/local/ssl

# make/set working directory for components
mkdir $PROJ_MAIN
cd $PROJ_MAIN
check_err "Unable to create working directory"

# grab latest projects from http://openssl.org/source
wget http://www.openssl.org/source/openssl-$SSLVER.tar.gz
wget http://www.openssl.org/source/openssl-fips-$FIPSVER.tar.gz

# check file validity
sha1sum openssl-$SSLVER.tar.gz | grep `curl http://www.openssl.org/source/openssl-$SSLVER.tar.gz.sha1`
sha1sum openssl-fips-$FIPSVER.tar.gz | grep `curl http://www.openssl.org/source/openssl-fips-$FIPSVER.tar.gz.sha1`

# decompress source tar(s)
tar zxvf openssl-fips-$FIPSVER.tar.gz
check_err "Unable to untar" openssl-fips-$FIPSVER.tar.gz
tar zxvf openssl-$SSLVER.tar.gz
check_err "Unable to untar" openssl-$SSLVER.tar.gz

# CD to work in the openssl-fips source directory
cd openssl-fips-$FIPSVER
check_err "Unable to cd to fips source dir"

# Build the FIPS object module
./config
make

# Copy fips project headers to standard openssl project source
cp fips/*.h ../openssl-$SSLVER/include/openssl/
check_err "cp for source files to target dir failed"

cp fips/rand/*.h ../openssl-$SSLVER/include/openssl/
check_err "cp for source files to target dir failed"

# Create /usr/local/ssl path and copy new openssl bin and fipsld (linker)
sudo mkdir -p /usr/local/ssl/fips-$FIPS_MAJOR/bin
check_err "Unable to create shared usr path for ssl"

sudo cp fips/fipsld /usr/local/ssl/fips-$FIPS_MAJOR/bin/
check_err "Unable to cp fipsld usr share for ssl"

sudo ln -s `which openssl` /usr/local/ssl/fips-$FIPS_MAJOR/bin/openssl
check_err "create soft link for openssl binary failed"

# CD to work in the standard release openssl source directory
cd $PROJ_MAIN
cd openssl-$SSLVER
check_err "Unable to switch to openssl source path"

# Build OpenSSL in FIPS capable mode
./config fips no-shared --with-fipslibdir=$PROJ_MAIN/openssl-fips-$FIPSVER/fips/
make depend
make

cd $PROJ_MAIN

# copy openssl components into /usr/local/ssl
sudo mkdir -p /usr/local/ssl/fips-$FIPS_MAJOR/lib
check_err "Unable to create path"

sudo mkdir -p /usr/local/ssl/lib/
check_err "Unable to create path"

sudo cp openssl-$SSLVER/libcrypto.a /usr/local/ssl/lib/
check_err "cp libcrypto.a failed"

sudo cp openssl-fips-$FIPSVER/fips/fips_premain.c /usr/local/ssl/fips-$FIPS_MAJOR/lib
check_err "cp fips_premain.c failed"

sudo cp openssl-fips-$FIPSVER/fips/fipscanister.o /usr/local/ssl/fips-$FIPS_MAJOR/lib
check_err "cp fipscanister.o failed"

sudo cp openssl-fips-$FIPSVER/fips/*.sha1 /usr/local/ssl/fips-$FIPS_MAJOR/lib
check_err "cp fipscanister.o.sha1 and fips_premain.c.sha1 failed"

cd $PROJ_MAIN


