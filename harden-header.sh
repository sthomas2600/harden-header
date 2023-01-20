#!bin/bash

#Very basic script to implment the steps listed in "How to harden HTTP response headers of Monster Ui portal"

#Check /etc/httpd/conf.modules.d/00-base.conf and see if the value LoadModule rewrite_module modules/mod_rewrite.so is present but commented out and then uncomment.
sed -i '/^#\s*LoadModule rewrite_module modules\/mod_rewrite.so/s/^#\s*//g' /etc/httpd/conf.modules.d/00-base.conf
#We then check to see if it is present uncommented now, if not we add it.
sed -i '$ a LoadModule rewrite_module modules/mod_rewrite.so' /etc/httpd/conf.modules.d/00-base.conf

#Search inbetween the Directory /var/www/html tags and replace AllowOverride None with llowOverride All.
sed -i '/<Directory "\/var\/www\/html">/,/<\/Directory>/s/AllowOverride None/AllowOverride All/' /etc/httpd/conf/httpd.conf

#If ServerTokens Prod and ServerSignature Off not present, then add to the bottom of the doc.
sed -i -e '$a\ServerSignature Off\nServerTokens Prod' -e '/ServerSignature Off/d; /ServerTokens Prod/d' /etc/httpd/conf/httpd.conf

#Checks to see if .htaccess if present or not and if it is, does it already contain any IfModule mod_headers.c contents, if so it doesn't bother updating and recommends manually changing it.
if ([ ! -f /var/www/html/.htaccess ]) || ([ -f /var/www/html/.htaccess ] && [ `grep "<IfModule mod_headers.c>" /var/www/html/.htaccess|wc -l` = "0" ]);then
tee -a /var/www/html/.htaccess <<EOF
<IfModule mod_headers.c>
	Header set X-XSS-Protection "1; mode=block"
	Header always append X-Frame-Options SAMEORIGIN
	Header set X-Content-Type-Options nosniff
	Header set Content-Security-Policy "upgrade-insecure-requests"
	Header set Referrer-Policy "same-origin"
	Header always set Permissions-Policy "camera=(),microphone=()"
	Header unset Server
</IfModule>
	# Strict-Transport-Security
<IfModule mod_headers.c>
	Header always set Strict-Transport-Security "max-age=31536000; includeSubDomains"
</IfModule>
	ServerSignature Off
EOF
systemctl restart httpd
clear
echo Complete
else 
	echo "/var/www/html/.htaccess already exists and potentially contains <IfModule mod_headers.c>, this should be edited manually."
	echo "FAILED"
fi

