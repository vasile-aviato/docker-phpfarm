#!/bin/bash
# this script builds everything for docker

if [ -z "$PHP_FARM_VERSIONS" ]; then
    echo "PHP versions not set! Aborting setup" >&2
    exit 1
fi

# build and symlink to major.minor
for VERSION in $PHP_FARM_VERSIONS
do
    V=$(echo $VERSION | awk -F. '{print $1"."$2}')

    # compile the PHP version
    ./compile.sh $VERSION
    ln -s "/phpfarm/inst/php-$VERSION/" "/phpfarm/inst/php-$V"
    ln -s "/phpfarm/inst/bin/php-$VERSION" "/phpfarm/inst/bin/php-$V"
    ln -s "/phpfarm/inst/bin/php-cgi-$VERSION" "/phpfarm/inst/bin/php-cgi-$V"
    ln -s "/phpfarm/inst/bin/phpize-$VERSION" "/phpfarm/inst/bin/phpize-$V"
    ln -s "/phpfarm/inst/bin/php-config-$VERSION" "/phpfarm/inst/bin/php-config-$V"

    # compile xdebug
    if [ "$V" == "5.2" ] || [ "$V" == "5.3" ]; then
        XDBGVERSION="2.2.7"
    else
        XDBGVERSION="2.4.0"
    fi
    wget https://xdebug.org/files/xdebug-$XDBGVERSION.tgz && \
    tar -xzvf xdebug-$XDBGVERSION.tgz && \
    cd xdebug-$XDBGVERSION && \
    phpize-$V && \
    ./configure --enable-xdebug --with-php-config=/phpfarm/inst/bin/php-config-$V && \
    make && \
    cp -v modules/xdebug.so /phpfarm/inst/php-$V/lib/ && \
    echo "zend_extension_debug = /phpfarm/inst/php-$V/lib/xdebug.so" >> /phpfarm/inst/php-$V/lib/php.ini && \
    echo "zend_extension = /phpfarm/inst/php-$V/lib/xdebug.so" >> /phpfarm/inst/php-$V/lib/php.ini && \
    cd .. && \
    rm -rf xdebug-$XDBGVERSION && \
    rm -f xdebug-$XDBGVERSION.tgz

    # enable apache config - compatible with wheezy and jessie
    a2ensite php-$V.conf
done

# print what have installed
ls -l /phpfarm/inst/bin/

# enable rewriting
a2enmod rewrite

# clean up sources
rm -rf /phpfarm/src
apt-get clean
rm -rf /var/lib/apt/lists/*
