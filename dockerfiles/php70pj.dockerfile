# =============================================================================
# naqoda/centos-apache-php
#
# CentOS-7, Apache 2.4.6-40, PHP 5.6.25
#
# =============================================================================
FROM centos:centos7

MAINTAINER Boris Yanez-Velasco <borisy@gmail.com>
USER root
# -----------------------------------------------------------------------------
# Import the RPM GPG keys for Repositories
# -----------------------------------------------------------------------------
RUN rpm -Uvh https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm

RUN yum -y update

# -----------------------------------------------------------------------------
# UTC Timezone & Networking
# -----------------------------------------------------------------------------
RUN ln -sf /usr/share/zoneinfo/UTC /etc/localtime \
	&& echo "NETWORKING=yes" > /etc/sysconfig/network

# -----------------------------------------------------------------------------
# Apache 2.4.6
# -----------------------------------------------------------------------------
RUN	yum --setopt=tsflags=nodocs -y install \
	unzip \
	httpd \
	mod_ssl \
	mod_ldap \
	mod_authnz_ldap \
	mod_rewrite \
	&& rm -rf /var/cache/yum/* \
	&& yum clean all

# -----------------------------------------------------------------------------
# PHP 7.0
# -----------------------------------------------------------------------------
RUN yum -y install epel-release.noarch yum-utils
RUN yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm
RUN yum-config-manager --enable remi-php70
RUN yum -y install php
RUN yum -y install php-mcrypt php-pecl-xdebug php-pecl php-mysqlnd php-pecl-apcu php-pecl-apcu-bc php-xml php-cli  \
	&& rm -rf /var/cache/yum/* \
	&& yum clean all

RUN yum -y install holland-mysqldump && rm -rf /var/cache/yum/* 	&& yum clean all

RUN yum -y install composer && rm -rf /var/cache/yum/* 	&& yum clean all
# -----------------------------------------------------------------------------
# SSH Client for SSH tunnel to dev MySQL Server, remove when no longer needed
# -----------------------------------------------------------------------------
RUN yum -y install openssh-clients

#RUN mkdir  /etc/httpd/conf.d/ssl/
#RUN openssl genrsa -des3 -passout pass:x -out /etc/httpd/conf.d/ssl/server.pass.key 2048 && \
#    openssl rsa -passin pass:x -in /etc/httpd/conf.d/ssl/server.pass.key -out  /etc/httpd/conf.d/ssl/server.key && \
#    rm  /etc/httpd/conf.d/ssl/server.pass.key
#
#RUN openssl req -new -key  /etc/httpd/conf.d/ssl/server.key -out  /etc/httpd/conf.d/ssl/server.csr   \
#          -subj "/C=US/ST=Massachusetts/L=Dukes/O=BYV/OU=IT Department/CN=payjoy.localhost" && \
#    openssl x509 -req -sha256 -days 365 -in  /etc/httpd/conf.d/ssl/server.csr \
#        -signkey  /etc/httpd/conf.d/ssl/server.key -out  /etc/httpd/conf.d/ssl/server.crt


# -----------------------------------------------------------------------------
# Vim
# -----------------------------------------------------------------------------
RUN yum -y install vim

# -----------------------------------------------------------------------------
# Global Apache configuration changes
# -----------------------------------------------------------------------------
RUN sed -i \
	-e 's~^ServerSignature On$~ServerSignature Off~g' \
	-e 's~^ServerTokens OS$~ServerTokens Prod~g' \
	-e 's~^DirectoryIndex \(.*\)$~DirectoryIndex \1 index.php~g' \
	-e 's~^NameVirtualHost \(.*\)$~#NameVirtualHost \1~g' \
	-e 's/AllowOverride none/AllowOverride All/g' \
	-e 's/AllowOverride None/AllowOverride All/g' \
	/etc/httpd/conf/httpd.conf

# -----------------------------------------------------------------------------
# Disable all Apache modules and enable the minimum
# -----------------------------------------------------------------------------
RUN sed -i \
	-e 's~^\(LoadModule .*\)$~#\1~g' \
	-e 's~^\(#LoadModule version_module modules/mod_version.so\)$~\1\n#LoadModule reqtimeout_module modules/mod_reqtimeout.so~g' \
	-e 's~^#LoadModule mime_module ~LoadModule mime_module ~g' \
	-e 's~^#LoadModule log_config_module ~LoadModule log_config_module ~g' \
	-e 's~^#LoadModule setenvif_module ~LoadModule setenvif_module ~g' \
	-e 's~^#LoadModule status_module ~LoadModule status_module ~g' \
	-e 's~^#LoadModule authz_host_module ~LoadModule authz_host_module ~g' \
	-e 's~^#LoadModule dir_module ~LoadModule dir_module ~g' \
	-e 's~^#LoadModule alias_module ~LoadModule alias_module ~g' \
	-e 's~^#LoadModule rewrite_module ~LoadModule rewrite_module ~g' \
	-e 's~^#LoadModule expires_module ~LoadModule expires_module ~g' \
	-e 's~^#LoadModule deflate_module ~LoadModule deflate_module ~g' \
	-e 's~^#LoadModule headers_module ~LoadModule headers_module ~g' \
	-e 's~^#LoadModule alias_module ~LoadModule alias_module ~g' \
	/etc/httpd/conf/httpd.conf

# -----------------------------------------------------------------------------
# Enable ServerStatus access via /_httpdstatus to local client
# -----------------------------------------------------------------------------
RUN sed -i \
	-e '/#<Location \/server-status>/,/#<\/Location>/ s~^#~~' \
	-e '/<Location \/server-status>/,/<\/Location>/ s~Allow from .example.com~Allow from localhost 127.0.0.1~' \
	/etc/httpd/conf/httpd.conf

COPY conf/httpd.conf /etc/httpd/conf/httpd.conf
COPY conf/php.ini  /etc/php.ini
# -----------------------------------------------------------------------------
# Configure Xdebug
# -----------------------------------------------------------------------------
RUN sed -i \
        -e '$ a xdebug.remote_enable=1' \
        -e '$ a xdebug.remote_port=9001' \
        -e '$ a xdebug.idekey="PAYJOY_XDEBUG"' \
        -e '$ a xdebug.remote_mode=req' \
        -e '$ a xdebug.remote_connect_back=0' \
        -e "$ a xdebug.remote_host=host.docker.internal" \
        -e '$ a xdebug.remote_autostart=true' \
        /etc/php.d/15-xdebug.ini

# -----------------------------------------------------------------------------
# Add default service users
# -----------------------------------------------------------------------------
RUN useradd -u 501 -d /var/www/html -m app \
	&& useradd -u 502 -d /var/www/html -M -s /sbin/nologin -G app app-www \
	&& usermod -a -G app-www app \
	&& usermod -a -G app-www apache \
    && usermod -a -G apache app \
    && usermod -a -G apache app-www

# -----------------------------------------------------------------------------
# Add a symbolic link to the app users home within the home directory &
# Create the initial directory structure
# -----------------------------------------------------------------------------
#RUN ln -s /var/www/html /home/app \
#	&& mkdir -p /var/www/html/{public_html,var/{log,session}}

# -----------------------------------------------------------------------------
# Set permissions (app:app-www)
# -----------------------------------------------------------------------------
RUN chown -R app:app-www /var/www/html \
	&& chmod 775 /var/www/html
#	&& chmod g+w /var/www/html/var/session
#RUN chown -R app:app-www /var/lib/php/session \
#	&& chown -R app:app-www /var/lib/php/wsdlcache


# -----------------------------------------------------------------------------
# Set default environment variables used to identify the service container
# -----------------------------------------------------------------------------
ENV SERVICE_UNIT_APP_GROUP app-1
ENV SERVICE_UNIT_LOCAL_ID 1
ENV SERVICE_UNIT_INSTANCE 1

# -----------------------------------------------------------------------------
# Set default environment variables used to configure the service container
# -----------------------------------------------------------------------------
ENV APACHE_SERVER_ALIAS ""
ENV APACHE_SERVER_NAME payjoy.localhost
ENV APP_HOME_DIR /var/www/html
ENV DATE_TIMEZONE UTC
ENV HTTPD /usr/sbin/httpd
ENV SERVICE_USER app
ENV SERVICE_USER_GROUP app-www
ENV SERVICE_USER_PASSWORD ""
ENV SUEXECUSERGROUP false
ENV TERM xterm

# -----------------------------------------------------------------------------
# Set ports
# -----------------------------------------------------------------------------
EXPOSE 80

CMD ["/usr/sbin/httpd", "-DFOREGROUND"]
