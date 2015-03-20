FROM centos:centos6.6
MAINTAINER pinguoops <pinguo-ops@camera360.com>

# -----------------------------------------------------------------------------
# Install Software & Libraries
# -----------------------------------------------------------------------------
# Disabled selinux
#RUN /usr/sbin/setenforce 0 \
#	&& sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config
	
ADD http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm  /root/
RUN rpm -Uvh /root/epel-release-6-8.noarch.rpm

RUN yum -y install \
    gcc gcc-c++ perl-CPAN zlib-devel gettext-devel tcl \
    tar wget git vim screen python-pip supervisor \
    openssh-server openssh sudo unzip file

# libraries for php & nginx
# m4 for autoconf
RUN yum -y install \
    gd gd-devel libjpeg libjpeg-devel libpng libpng-devel curl \
    freetype freetype-devel libtool libtool-ltdl libtool-ltdl-devel \
    libxml2 libxml2-devel zlib zlib-devel bzip2 bzip2-devel \
    curl-devel gettext gettext-devel libevent libevent-devel \
    libxslt-devel expat expat-devel unixODBC unixODBC-devel \
    libmemcached libmemcached-devel openssl openssl-devel libxslt \
    libmcrypt libmcrypt-devel freetds freetds-devel \
    ImageMagick ImageMagick-devel pcre pcre-devel m4

# using by php ampq
#RUN cd /root \
#    && wget -q -O rabbitmq-c-v0.5.2.zip https://github.com/alanxz/rabbitmq-c/archive/v0.5.2.zip \
#    && unzip -q rabbitmq-c-v0.5.2.zip \
#    && ls -l \
#    && cd rabbitmq-c-0.5.2 \
#    && autoreconf -i \
#    && ./configure 1>/dev/null \
#    && make 1>/dev/null \
#    && make install

#RUN \
#    curl "https://bootstrap.pypa.io/get-pip.py" -o "get-pip.py" && \
#    python get-pip.py && \
#    pip install awscli

# -----------------------------------------------------------------------------
# Configure, timezone/sshd/passwd/networking
# -----------------------------------------------------------------------------

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && sed -i \
        -e 's/^UsePAM yes/#UsePAM yes/g' \
        -e 's/^#UsePAM no/UsePAM no/g' \
        -e 's/#UsePrivilegeSeparation.*/UsePrivilegeSeparation no/g' \
        -e 's/^#UseDNS yes/UseDNS no/g' \
        /etc/ssh/sshd_config \
    && echo "root" | passwd --stdin root \
    && ssh-keygen -q -b 1024 -N '' -t rsa -f /etc/ssh/ssh_host_rsa_key \
    && ssh-keygen -q -b 1024 -N '' -t dsa -f /etc/ssh/ssh_host_dsa_key \
    && echo "NETWORKING=yes" > /etc/sysconfig/network

# set system limits
RUN	sed -i "/# End of file/i\\* soft nofile 65536" /etc/security/limits.conf \
	&& sed -i "/# End of file/i\\* hard nofile 65536" /etc/security/limits.conf \
	&& sed -i "/# End of file/i\\* soft nproc 10240" /etc/security/limits.conf \
	&& sed -i "/# End of file/i\\* hard nproc 10240" /etc/security/limits.conf \
	&& sed -i "s/^\(*          soft    nproc     1024\)/#\1/" /etc/security/limits.d/90-nproc.conf	
		


# config time service
RUN yum -y install ntp \
	&& chkconfig --level 345 ntpd on \
	&& chkconfig --level 345 ntpdate off \
	&& /sbin/service ntpd start \
	&& /sbin/service ntpdate stop


	
# -----------------------------------------------------------------------------
# Clear Cache
# -----------------------------------------------------------------------------
RUN rm -rvf /var/cache/{yum,ldconfig}/* \
    && rm -rvf /etc/ld.so.cache \
    && rm -rvf /root/* \
    && yum clean all

# -----------------------------------------------------------------------------
# Add user worker
# -----------------------------------------------------------------------------
RUN useradd -m -u 1000 worker \
    && echo "worker" | passwd --stdin worker \
    && echo 'worker  ALL=(ALL)  NOPASSWD: ALL' > /etc/sudoers.d/worker

# -----------------------------------------------------------------------------
# change user and make initials
# -----------------------------------------------------------------------------
USER worker
ENV HOME /home/worker
ENV SRC_DIR ${HOME}/src
RUN mkdir -p ${SRC_DIR} ${HOME}/bin

# -----------------------------------------------------------------------------
# Install PHP
# -----------------------------------------------------------------------------
ENV phpversion 5.3.28
ENV PHP_INSTALL_DIR ${HOME}/php
RUN cd ${SRC_DIR} \
    && wget -q -O php-${phpversion}.tar.gz http://ar2.php.net/distributions/php-${phpversion}.tar.gz \
    && tar xzf php-${phpversion}.tar.gz \
    && ls -l \
    && cd php-${phpversion} \
    && ./configure --prefix=${PHP_INSTALL_DIR} --with-libdir=lib64 --enable-fpm --with-mysql=mysqlnd --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --with-pdo-odbc=unixODBC,/usr --with-gd --with-jpeg-dir --with-png-dir --with-zlib-dir --with-freetype-dir --enable-gd-native-ttf --with-zlib --with-bz2 --with-openssl --with-curl --with-mcrypt --with-mhash --enable-zip --enable-exif --enable-ftp --enable-mbstring --enable-bcmath --enable-pcntl --enable-soap --enable-sockets --enable-sysvmsg --enable-sysvsem --enable-sysvshm --with-gettext --with-xsl --enable-wddx --with-libexpat-dir --with-xmlrpc 1>/dev/null \
    && make 1>/dev/null \
    && make install \
    && cp php.ini-development ${PHP_INSTALL_DIR}/lib/php.ini

RUN ln -s ${PHP_INSTALL_DIR}/bin/php ${HOME}/bin/php \
    && ln -s ${PHP_INSTALL_DIR}/bin/phpize ${HOME}/bin/phpize \
    && ln -s ${PHP_INSTALL_DIR}/bin/php-config ${HOME}/bin/php-config

RUN mkdir -p ${SRC_DIR}/tmp \
    && cd ${PHP_INSTALL_DIR} \
    && bin/pear config-set php_ini ${PHP_INSTALL_DIR}/lib/php.ini \
    && bin/pear config-set temp_dir ${SRC_DIR}/tmp/pear/ \
    && bin/pear config-set cache_dir ${SRC_DIR}/tmp/pear/cache \
    && bin/pear config-set download_dir ${SRC_DIR}/tmp/pear/download \
    && bin/pecl channel-update pecl.php.net \
    && bin/pecl install redis-2.2.7 1>/dev/null \
    && bin/pecl install igbinary-1.2.1 1>/dev/null \
    && bin/pecl install memcached-2.2.0 1>/dev/null \
    && bin/pecl install memcache-3.0.8 1>/dev/null \
    && bin/pecl install apc-3.1.13 1>/dev/null \
    && bin/pecl install mongo-1.6.5 1>/dev/null \
    && bin/pecl install xdebug-2.2.7 1>/dev/null \
    && bin/pecl install xhprof-0.9.4 1>/dev/null \
	&& bin/pecl install amqp-1.4.0 1>/dev/null \
    && bin/pecl install imagick-3.2.0RC1 1>/dev/null

# -----------------------------------------------------------------------------
# Install RabbitMq PHP extensions
# -----------------------------------------------------------------------------
RUN cd ${SRC_DIR} \
    && wget -q -O php-signal-handler-master.zip https://github.com/rstgroup/php-signal-handler/archive/master.zip \
    && unzip -q php-signal-handler-master.zip \
    && ls -l \
    && cd php-signal-handler-master \
    && ${PHP_INSTALL_DIR}/bin/phpize \
    && ./configure --with-php-config=$PHP_INSTALL_DIR/bin/php-config 1>/dev/null \
    && make 1>/dev/null \
    && make install

# -----------------------------------------------------------------------------
# Install Nginx
# -----------------------------------------------------------------------------
ENV nginx_version 1.4.2
ENV NGINX_INSTALL_DIR ${HOME}/nginx

RUN cd ${SRC_DIR} \
    && wget -q -O nginx-${nginx_version}.tar.gz http://nginx.org/download/nginx-${nginx_version}.tar.gz \
    && wget -q -O nginx-http-concat-master.zip https://github.com/alibaba/nginx-http-concat/archive/master.zip \
    && wget -q -O nginx-logid-master.zip https://github.com/pinguo-liuzhaohui/nginx-logid/archive/master.zip  \
    && tar xzf nginx-${nginx_version}.tar.gz \
    && unzip -q nginx-http-concat-master.zip \
    && unzip -q nginx-logid-master.zip \
    && ls -l \
    && cd nginx-${nginx_version} \
    && ./configure --prefix=$NGINX_INSTALL_DIR --with-http_stub_status_module --with-http_ssl_module --add-module=../nginx-http-concat-master --add-module=../nginx-logid-master 1>/dev/null \
    && make 1>/dev/null \
    && make install

# -----------------------------------------------------------------------------
# Clear
# -----------------------------------------------------------------------------
RUN rm -rf ${SRC_DIR} \
    && ls -l ${HOME}

EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]