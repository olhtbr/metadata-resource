FROM busybox:1.26
LABEL maintainer "olhtbr@gmail.com"

COPY check in out /opt/resource/
RUN chmod -x /opt/resource/*
