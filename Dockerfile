FROM haproxy:2.1

RUN mkdir /conf && chmod -R 700 /conf && chown -R haproxy:haproxy /conf
USER haproxy
EXPOSE 8000

COPY run.sh /
ENTRYPOINT ["/run.sh"]
