FROM debian:stretch

ENV SEAFILE_VERSION 6.1.1

# This is for patching run scripts to keep running as long as they think Seafile is still running
# (I can't believe how dirty this is, but there is no other documentated way)
# https://github.com/haiwen/seafile/issues/930
COPY keep-running.patch /

RUN apt-get update && \
    apt-get -y install --no-install-recommends --no-install-suggests wget ca-certificates patchutils procps supervisor python-setuptools python-imaging python-ldap python-mysqldb python-memcache python-urllib3 && \
    mkdir /seafile && \
    wget -O "/seafile/seafile-current.tar.gz" "https://bintray.com/artifact/download/seafile-org/seafile/seafile-server_${SEAFILE_VERSION}_x86-64.tar.gz" && \
    tar xzvf /seafile/seafile-current.tar.gz -C /seafile && \
    rm /seafile/seafile-current.tar.gz && \
    cd "/seafile/seafile-server-${SEAFILE_VERSION}" && \
    patch -p1 < /keep-running.patch && \
    ln -s "/seafile/seafile-server-${SEAFILE_VERSION}" "/seafile/seafile-server-latest" && \
    ln -s "/seafile/seafile-server-latest/seahub/media" "/seafile/seahub-data" && \
    apt-get purge -y wget ca-certificates patchutils && \
    apt-get autoremove -y && \
    rm -rf /var/cache/apt/*

ADD rootfs /

EXPOSE 8000 8080 8082 9000
ENTRYPOINT ["/entrypoint.sh"]
CMD ["supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]