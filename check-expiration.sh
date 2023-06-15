#!/bin/bash

DAYS=25
notify="admin@barrydegraaff.nl"

expDates=$(/opt/zimbra/bin/zmcertmgr viewdeployedcrt | grep notAfter| awk -F '=' '{print $2}')
inXdays=$(($(date +%s) + (86400*$DAYS)));

while IFS= read -r expDate; do
   expirationDate=$(date -d "$expDate" +%s)

   if [ $inXdays -gt $expirationDate ]; then
      echo -e "Subject:Zimbra TLS certificate is about to expire \n\nA Zimbra TLS certificate is about to expire, please be advised that even if you use a proxy with a certificate that does not expire, Zimbra LDAP requires a certificate that has not expired.\n\n\nOutput from zmcertmgr viewdeployedcrt:\n`/opt/zimbra/bin/zmcertmgr viewdeployedcrt`\n\n\nFor immediate remediation see: https://wiki.zimbra.com/wiki/Regenerate_Self-Signed_SSL_Certificate_-_Single-Server\n" | /opt/zimbra/common/sbin/sendmail $notify
   fi;
done <<< "$expDates"

#In case the certificate was renewed but Zimbra not restarted, zmcertmgr viewdeployedcrt shows certificate that will be used after restart, so check the running cert manually
expDate=$(cat /opt/zimbra/ssl/zimbra/server/server.crt | /opt/zimbra/common/bin/openssl x509 -noout -enddate | grep notAfter| awk -F '=' '{print $2}')
expirationDate=$(date -d "$expDate" +%s)

if [ $inXdays -gt $expirationDate ]; then
   echo -e "Subject:Zimbra TLS certificate is about to expire \n\nA Zimbra TLS certificate (/opt/zimbra/ssl/zimbra/server/server.crt) is about to expire, please be advised that even if you use a proxy with a certificate that does not expire, Zimbra LDAP requires a certificate that has not expired.\n\n\n`cat /opt/zimbra/ssl/zimbra/server/server.crt | /opt/zimbra/common/bin/openssl x509 -noout -enddate -startdate -subject`\n\n\nFor immediate remediation see: https://wiki.zimbra.com/wiki/Regenerate_Self-Signed_SSL_Certificate_-_Single-Server\n" | /opt/zimbra/common/sbin/sendmail $notify
fi;

exit 0
