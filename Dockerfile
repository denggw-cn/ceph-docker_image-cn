# CEPH DAEMON IMAGE
# CEPH VERSION: Luminous
# CEPH VERSION DETAIL: 12.x.x

FROM centos:7
MAINTAINER Deng Guowei "cbldgv@qq.com"

ENV CEPH_VERSION luminous
ENV CONFD_VERSION 0.10.0

ADD s3cfg /root/.s3cfg

# Add bootstrap script, ceph defaults key/values for KV store
ADD *.sh ceph.defaults check_zombie_mons.py ./osd_scenarios/* entrypoint.sh.in disabled_scenario forego-stable-linux-amd64.tgz confd-0.10.0-linux-amd64 /

ARG PACKAGES="unzip ceph-mon ceph-osd ceph-mds ceph-mgr ceph-base ceph-common ceph-radosgw rbd-mirror device-mapper sharutils etcd kubernetes-client e2fsprogs s3cmd wget nfs-ganesha nfs-ganesha-ceph nfs-ganesha-rgw"

# Install Ceph
ADD install.repo /etc/yum.repos.d/

RUN  rm -rf /etc/yum.repos.d/CentOS-* &&\
  rpm --import 'https://mirrors.aliyun.com/epel/RPM-GPG-KEY-EPEL-7Server' &&\
  rpm --import 'https://mirrors.aliyun.com/centos/RPM-GPG-KEY-CentOS-7' &&\
  rpm --import 'https://mirrors.aliyun.com/ceph/keys/release.asc' && \
  yum install -y $PACKAGES && \
  rpm -q $PACKAGES && \
  rm -rf /var/cache/yum

  # Install confd
RUN  mv confd-$CONFD_VERSION-linux-amd64 /usr/local/bin/confd &&\
  chmod +x /usr/local/bin/confd && mkdir -p /etc/confd/conf.d && mkdir -p /etc/confd/templates && \
  \
  # Download forego
  mv /forego /usr/local/bin/forego && \
  bash /clean_container.sh && rm /clean_container.sh

# Modify the entrypoint
RUN bash "/generate_entrypoint.sh" && \
  rm -f /generate_entrypoint.sh && \
  bash -n /*.sh

# Add templates for confd
ADD ./confd/templates/* /etc/confd/templates/
ADD ./confd/conf.d/* /etc/confd/conf.d/

# Add volumes for Ceph config and data
VOLUME ["/etc/ceph","/var/lib/ceph", "/etc/ganesha"]

# Execute the entrypoint
WORKDIR /
ENTRYPOINT ["/entrypoint.sh"]
