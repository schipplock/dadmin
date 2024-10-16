#!/bin/bash
# just one way to do it...it's the simple way :)
wget "http://user:password@dadmin.de/?page_id=expirecheck&s=whothebeepisAlice" -O /tmp/domainreport.txt
/var/www/websites/dadmin.de/tools/gsmtp.pl --username="foo@bar.com" --password="password" --from="foo@bar.com" --to="domains@company.com" --subject="Domainnamenreport" --message="Report siehe Anhang" --attachments="/tmp/domainreport.txt"
