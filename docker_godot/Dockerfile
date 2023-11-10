FROM go_v0

WORKDIR /www
COPY 50start.sh .
COPY /www/. .

COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf.template /etc/nginx/conf.d/nginx.conf

RUN chmod +x /www/50start.sh

RUN mv /www/50start.sh /docker-entrypoint.d

EXPOSE 80 443

STOPSIGNAL SIGQUIT

CMD ["nginx","-g","daemon off;"]
