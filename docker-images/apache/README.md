# mod_perl Docker image

```shell
docker build --force-rm --rm -t capullo -f Dockerfile .
docker run --rm -it --entrypoint bash capullo:latest
```

apache2
libapache2-mod-perl2
/var/run/apache2/apache2.pid

<VirtualHost *:80>
        #ServerName dadmin

        ServerAdmin webmaster@localhost
        DocumentRoot /var/www/html

        ErrorLog ${APACHE_LOG_DIR}/error.log
        CustomLog ${APACHE_LOG_DIR}/access.log combined

        <Location /var/www/html>
            SetHandler perl-script
            PerlResponseHandler ModPerl::Registry
            PerlOptions +ParseHeaders
            Options +ExecCGI
            Order allow,deny
            Allow from all
        </Location>

</VirtualHost>

#!/usr/bin/perl
print "Content-type: text/plain\n\n";
print "mod_perl 2.0 rocks!\n";

a2enmod cgid