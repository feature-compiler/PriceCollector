FROM tarantool/tarantool:1
MAINTAINER doc@tarantool.org

COPY *.lua /opt/tarantool/
EXPOSE 3301
WORKDIR /opt/tarantool

CMD ["tarantool", "server.lua"]
