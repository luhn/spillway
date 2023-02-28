FROM haproxy:2.6

EXPOSE 8000
COPY --chown=haproxy:haproxy empty.cfg /usr/local/etc/haproxy/haproxy.cfg

COPY run.sh /usr/local/
ENTRYPOINT ["/usr/local/run.sh"]
