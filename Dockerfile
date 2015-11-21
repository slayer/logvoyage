FROM phusion/baseimage:0.9.16
MAINTAINER Vlad Moskovets <devvlad@gmail.com>

# Default to UTF-8 file.encoding
ENV LANG C.UTF-8

RUN apt-get update && apt-get install -y redis-server

#########################
#
#       JAVA part
#
#########################
ENV CA_CERTIFICATES_JAVA_VERSION 20140324
RUN add-apt-repository -y ppa:openjdk-r/ppa
RUN set -x \
  && apt-get update && apt-get install -y --no-install-recommends \
      libfontconfig1 \
      openjdk-8-jre-headless \
      ca-certificates-java

# see CA_CERTIFICATES_JAVA_VERSION notes above # debug
RUN /var/lib/dpkg/info/ca-certificates-java.postinst configure

# java interactive install fails :(
# RUN add-apt-repository -y ppa:webupd8team/java \
#     && apt-get update \
#     && apt-get install -y --no-install-recommends ca-certificates-java oracle-java8-installer


#########################
#
#  ElasticSearch part
#
#########################
# grab gosu for easy step-down from root
RUN gpg --keyserver ha.pool.sks-keyservers.net --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN arch="$(dpkg --print-architecture)" \
  && set -x \
  && curl -o /usr/local/bin/gosu -fSL "https://github.com/tianon/gosu/releases/download/1.3/gosu-$arch" \
  && curl -o /usr/local/bin/gosu.asc -fSL "https://github.com/tianon/gosu/releases/download/1.3/gosu-$arch.asc" \
  && gpg --verify /usr/local/bin/gosu.asc \
  && rm /usr/local/bin/gosu.asc \
  && chmod +x /usr/local/bin/gosu

RUN apt-key adv --keyserver ha.pool.sks-keyservers.net --recv-keys 46095ACC8548582C1A2699A9D27D666CD88E42B4

ENV ELASTICSEARCH_MAJOR 1.5
ENV ELASTICSEARCH_VERSION 1.5.2
ENV ELASTICSEARCH_REPO_BASE http://packages.elasticsearch.org/elasticsearch/1.5/debian

RUN echo "deb $ELASTICSEARCH_REPO_BASE stable main" > /etc/apt/sources.list.d/elasticsearch.list

RUN set -x \
  && apt-get update \
  && apt-get install -y --no-install-recommends elasticsearch=$ELASTICSEARCH_VERSION \
  && rm -rf /var/lib/apt/lists/*

ENV PATH /usr/share/elasticsearch/bin:$PATH

RUN set -ex \
  && for path in \
    /usr/share/elasticsearch/data \
    /usr/share/elasticsearch/logs \
    /usr/share/elasticsearch/config \
    /usr/share/elasticsearch/config/scripts \
  ; do \
    mkdir -p "$path"; \
    chown -R elasticsearch:elasticsearch "$path"; \
  done

COPY etc /etc
RUN ln -s /etc/elasticsearch/logging.yml /usr/share/elasticsearch/config/logging.yml
RUN sed -i 's/daemonize yes/daemonize no/' /etc/redis/redis.conf
VOLUME /usr/share/elasticsearch/data
EXPOSE 9200 9300

#########################
#
#     LogVoyage part
#
#########################
COPY logvoyage /app/logvoyage
COPY web/templates /app/web/templates
COPY static /app/static
EXPOSE 3000 12345

