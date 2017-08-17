#!/usr/local/bin/bash
#Requirements: etckeeper, diffcolor

#This script concatenates multiple files of haproxy configuration into
#one file, and than checks if monolithic config contains errors. If everything is
#OK with new config script will write new config to $CURRENTCFG and reload haproxy
#Also, script will commit changes to etckeeper, if you don't use etckeeper you
#should start using it.
#Script assumes following directory structure:
#/usr/local/etc/haproxy/conf.d/
#├── global.cfg
#├── stats.cfg
#├── pcl.cfg
#├── others.cfg
#Every site has it's own file, so you can disable site by changing it's file extension, or appending .disabled. 
#You can add ad many files as needed to create as many sections you require in your haproxy.conf file.


CURRENTCFG=/usr/local/etc/haproxy.conf
NEWCFG=/tmp/haproxy.cfg.tmp
CONFIGDIR=/usr/local/etc/haproxy.d

echo "Compiling *.cfg files from $CONFIGDIR"
ls -la $CONFIGDIR/*.cfg
cat $CONFIGDIR/*.cfg > $NEWCFG
echo "Differences between current and new config"
diff -s -U 3 $CURRENTCFG $NEWCFG | colordiff
if [ $? -ne 0 ]; then
        echo "You should make some changes first :)"
        exit 1 #Exit if old and new configuration are the same
fi
echo -e "Checking if new config is valid..."
haproxy -c -f $NEWCFG

if [ $? -eq 0 ]; then
#        echo "Check if there are some warnings in new configuration."
#        read -p "Should I copy new configuration to $CURRENTCFG and reload haproxy? [y/N]" -n 1 -r
#        if [[ $REPLY =~ ^[Yy]$ ]]
#        then
                echo " "
                echo "Working..."
                cat $CONFIGDIR/*.cfg > $CURRENTCFG
                # etckeeper commit -m "Updating haproxy configuration"
                echo "Reloading haproxy..."
                service haproxy reload
#        fi
else
        echo "There are errors in new configuration, please fix them and try again."
        exit 1
fi
