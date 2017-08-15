#!/usr/local/bin/bash
#
function makeBackup() {
    DateTimeStamp=$(date '+%m-%d-%y_%H:%M:%S')
    Original=$1
    FileName=$(basename $Original)
    Directory=$(dirname $Original)
    cp $Original ${Directory}/backup/${DateTimeStamp}_${FileName}
}

makeBackup /usr/local/etc/haproxy.conf
#
ee $Original