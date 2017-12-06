FROM ubuntu:16.04

ARG branch=master
ARG version

ENV name="apache-occi"
ENV logDir="/var/log/${name}" \
    TERM="xterm"

LABEL application=${name} \
      description="Apache server for use with keystorm" \
      maintainer="kimle@cesnet.cz" \
      version=${version} \
      branch=${branch}

SHELL ["/bin/bash", "-c"]

# update + dependencies
RUN apt-get update && \
    apt-get --assume-yes upgrade && \
    DEBIAN_FRONTEND=noninteractive apt-get --assume-yes install apache2 libapache2-mod-auth-openidc jq gettext-base curl apt-transport-https

# EGI trust anchors + gridsite
RUN set -o pipefail && \
    curl -s https://dist.eugridpma.info/distribution/igtf/current/GPG-KEY-EUGridPMA-RPM-3 | apt-key add - && \
    echo $'#### EGI Trust Anchor Distribution ####\n\
deb http://repository.egi.eu/sw/production/cas/1/current egi-igtf core' > /etc/apt/sources.list.d/egi.list && \
    curl -s http://scientific.zcu.cz/repos/jenkins-builder.asc | apt-key add - && \
    echo $'#### Gridsite ####\n\
deb https://emian.zcu.cz/job/gridsite/job/build-ssl1.0/platform=ubuntu-16-x86_64/18/artifact/results/ubuntu/ stable/\n\
deb-src https://emian.zcu.cz/job/gridsite/job/build-ssl1.0/platform=ubuntu-16-x86_64/18/artifact/results/ubuntu/ stable/' > /etc/apt/sources.list.d/gridsite.list && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get --assume-yes install ca-policy-egi-core gridsite libgridsite2

RUN mkdir -p ${logDir} && \
    chown -R www-data:www-data ${logDir}

COPY config/sslgridsite.load /etc/apache2/mods-available/

RUN a2dissite 000-default && \
    a2enmod ssl && \
    a2enmod headers && \
    a2enmod proxy && \
    a2enmod proxy_http && \
    a2enmod remoteip && \
    a2enmod auth_openidc && \
    a2enmod sslgridsite

COPY config/* /${name}/config/
COPY bin/* /${name}/bin/

VOLUME ["${logDir}"]

EXPOSE 5000

ENTRYPOINT ["/apache-occi/bin/apache-occi-wrapper.sh"]
