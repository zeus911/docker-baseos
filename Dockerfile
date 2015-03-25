FROM centos:centos6.6
MAINTAINER pinguoops <pinguo-ops@camera360.com>

# -----------------------------------------------------------------------------
# Configure, /selinux/epel/base software
# -----------------------------------------------------------------------------
# Disabled selinux
#RUN /usr/sbin/setenforce 0 \
#	&& sed -i '/SELINUX/s/enforcing/disabled/' /etc/selinux/config
	
ADD http://dl.fedoraproject.org/pub/epel/6/x86_64/epel-release-6-8.noarch.rpm  /tmp/
RUN rpm -Uvh /tmp/epel-release-6-8.noarch.rpm 

RUN yum -y install \
    gcc gcc-c++ make patch autoconf tcl mpir mpir-devel \
    tar wget git vim screen unzip \
    openssh-server openssh sudo file
	
RUN yum -y install \
    gd gd-devel libjpeg libjpeg-devel libpng libpng-devel curl \
    freetype freetype-devel libtool libtool-ltdl libtool-ltdl-devel \
    libxml2 libxml2-devel zlib zlib-devel bzip2 bzip2-devel \
    curl-devel gettext gettext-devel libevent libevent-devel \
    libxslt-devel expat expat-devel unixODBC unixODBC-devel \
    libmemcached libmemcached-devel openssl openssl-devel libxslt \
    libmcrypt libmcrypt-devel freetds freetds-devel \
    ImageMagick ImageMagick-devel pcre pcre-devel m4

RUN yum -y update bash openssl glibc

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

RUN mv /etc/sysctl.conf /etc/sysctl.conf.bak \
	&& echo '# Optimization kernel' > /etc/sysctl.conf \
	&& echo 'net.ipv4.tcp_max_syn_backlog = 65536' >> /etc/sysctl.conf \
	&& echo 'net.core.netdev_max_backlog =  60000' >> /etc/sysctl.conf \
	&& echo 'net.core.somaxconn = 60000' >> /etc/sysctl.conf \
	&& echo 'net.core.wmem_default = 67108864' >> /etc/sysctl.conf \
	&& echo 'net.core.rmem_default = 67108864' >> /etc/sysctl.conf \
	&& echo 'net.core.rmem_max = 134217728' >> /etc/sysctl.conf \
	&& echo 'net.core.wmem_max = 134217728' >> /etc/sysctl.conf \
	&& echo 'net.ipv4.tcp_timestamps = 0' >> /etc/sysctl.conf \
	&& echo 'net.ipv4.tcp_synack_retries = 2' >> /etc/sysctl.conf \
	&& echo 'net.ipv4.tcp_syn_retries = 2' >> /etc/sysctl.conf \
	&& echo 'net.ipv4.tcp_tw_recycle = 1' >> /etc/sysctl.conf \
	&& echo '#net.ipv4.tcp_tw_len = 1' >> /etc/sysctl.conf \
	&& echo 'net.ipv4.tcp_tw_reuse = 1' >> /etc/sysctl.conf \
	&& echo 'net.ipv4.tcp_mem = 94500000 915000000 927000000' >> /etc/sysctl.conf \
	&& echo 'net.ipv4.tcp_rmem = 4096 87380 33554432' >> /etc/sysctl.conf \
	&& echo 'net.ipv4.tcp_wmem = 4096 65536 33554432' >> /etc/sysctl.conf \
	&& echo 'net.ipv4.tcp_max_orphans = 3276800' >> /etc/sysctl.conf \
	&& echo 'net.ipv4.tcp_fin_timeout = 10' >> /etc/sysctl.conf \
	&& echo 'net.ipv4.tcp_keepalive_time = 10' >> /etc/sysctl.conf \
	&& echo 'net.ipv4.ip_local_port_range = 1024  65535' >> /etc/sysctl.conf \
	&& echo 'net.ipv4.tcp_max_tw_buckets = 10000' >> /etc/sysctl.conf \
	&& echo 'net.ipv4.tcp_max_syn_backlog = 8192000' >> /etc/sysctl.conf \
	&& echo 'net.nf_conntrack_max = 6553600' >> /etc/sysctl.conf \
	&& echo 'net.netfilter.nf_conntrack_max = 6553600' >> /etc/sysctl.conf \
	&& echo 'net.netfilter.nf_conntrack_tcp_timeout_established = 120' >> /etc/sysctl.conf \
	&& echo 'net.netfilter.nf_conntrack_tcp_timeout_time_wait = 120' >> /etc/sysctl.conf \
	&& echo 'net.netfilter.nf_conntrack_tcp_timeout_close_wait = 60' >> /etc/sysctl.conf \
	&& echo 'net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 120' >> /etc/sysctl.conf \
	&& echo 'vm.zone_reclaim_mode = 1' >> /etc/sysctl.conf \
	&& echo '# Add' >> /etc/rc.local \
	&& echo 'echo 0 > /proc/sys/net/ipv4/tcp_syncookies' >> /etc/rc.local \
	&& echo 'echo 0 > /proc/sys/vm/zone_reclaim_mode' >> /etc/rc.local \
	&& echo 'echo no > /sys/kernel/mm/redhat_transparent_hugepage/khugepaged/defrag' >> /etc/rc.local \
	&& echo 'echo never > /sys/kernel/mm/redhat_transparent_hugepage/defrag' >> /etc/rc.local
# -----------------------------------------------------------------------------
# Clear Cache
# -----------------------------------------------------------------------------
RUN rm -rvf /var/cache/{yum,ldconfig}/* \
    && rm -rvf /etc/ld.so.cache \
    && rm -rvf /tmp/* \
    && yum clean all

# -----------------------------------------------------------------------------
# Add user worker
# -----------------------------------------------------------------------------
RUN useradd -m -u 1000 worker \
    && echo "worker" | passwd --stdin worker \
    && echo 'worker  ALL=(ALL)  NOPASSWD: ALL' > /etc/sudoers.d/worker

# -----------------------------------------------------------------------------
# change user and make initials install python2.7.9
# -----------------------------------------------------------------------------
USER worker
ENV HOME /home/worker
# config bash_profile
RUN echo 'export PATH=$HOME/bin:$PATH' >> ${HOME}/.bash_profile \
	&& echo 'export PATH' >> ${HOME}/.bash_profile \
	&& echo '# PYTHON HOME' >> ${HOME}/.bash_profile \
	&& echo 'PYTHON_HOME=/home/worker/python/bin' >> ${HOME}/.bash_profile \
	&& echo 'PATH=$PYTHON_HOME:$PATH' >> ${HOME}/.bash_profile \
	&& echo 'export PATH' >> ${HOME}/.bash_profile
	
RUN mkdir -p ${HOME}/bin ${HOME}/src \
	&& cd ${HOME}/src/ \
	&& wget -q -O setuptools-14.3.1.tar.gz https://pypi.python.org/packages/source/s/setuptools/setuptools-14.3.1.tar.gz \
	&& wget -q -O pip-6.0.8.tar.gz https://pypi.python.org/packages/source/p/pip/pip-6.0.8.tar.gz \
	&& wget -q -O Python-2.7.9.tgz https://www.python.org/ftp/python/2.7.9/Python-2.7.9.tgz \
	&& tar xzvf Python-2.7.9.tgz 1>/dev/null \
	&& cd Python-2.7.9 \
	&& CXX=g++ ./configure --prefix=${HOME}/python 1>/dev/null \
	&& make 1>/dev/null \
	&& make install  1>/dev/null \
	&& cd ${HOME}/bin \
	&& ln -s ${HOME}/python/bin/python python \
	&& cd ${HOME}/src/ \
	&& tar xzvf setuptools-14.3.1.tar.gz 1>/dev/null \
	&& cd setuptools-14.3.1 \
	&& ${HOME}/python/bin/python setup.py install 1>/dev/null \
	&& cd ${HOME}/bin \
	&& ln -s ${HOME}/python/bin/easy_install easy_install \
	&& cd ${HOME}/src/ \
	&& tar xzvf pip-6.0.8.tar.gz 1>/dev/null \
	&& cd pip-6.0.8 \
	&& ${HOME}/python/bin/python setup.py install 1>/dev/null \
	&& cd ${HOME}/bin \
	&& ln -s /home/worker/python/bin/pip pip
	
EXPOSE 22
CMD ["/usr/sbin/sshd", "-D"]