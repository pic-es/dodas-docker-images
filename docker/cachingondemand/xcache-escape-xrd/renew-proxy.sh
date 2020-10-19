#!/bin/bash
#
# cred_proxy
#
# Create an x509 proxy from the host's igtf grid certificate and delegate
# against the osg fts server at https://fts01.pic.es:8446.  Run this script (as
# root) as a cronjob to maintain an FTS-delegated proxy for rucio operations.
#
## Configuration

proxytool=/usr/bin/voms-proxy-init
hostcert=/root/cachingondemand/xcache-escape-xrd/condemand01_pic_es_cert_2.cer
hostkey=/root/cachingondemand/xcache-escape-xrd/condemand01_pic_es_cert_2.key
#x509proxy=/opt/rucio/etc/web/x509up
x509proxy=/tmp/x509up_u02

## Logging info
dtstamp="`date +%F-%A-%H.%M.%S `"
echo -e "\n################ ${dtstamp} ################" 


## Create robot proxy
# echo $PASSPHRASE
echo -e "${dtstamp}: ${proxytool} -cert ${hostcert} -key ${hostkey} -out ${x509proxy} "

chown root: ${hostcert}
chown root: ${hostkey}

while true
do  
  echo $PASSPHRASE | ${proxytool} --cert ${hostcert} --key ${hostkey} --out ${x509proxy} -voms escape --valid 3000:00
  
  voms-proxy-info -all
  
  sleep 43100

done

