FROM tarantool/tarantool:1
MAINTAINER doc@tarantool.org

COPY *.lua /opt/tarantool/
EXPOSE 3301
ENV SECRET_KEY_AUTH="TOP_SECRET"
WORKDIR /opt/tarantool

CMD ["tarantool", "server.lua"]
