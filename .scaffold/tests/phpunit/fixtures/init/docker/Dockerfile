# hadolint global ignore=DL3018
FROM alpine:3@sha256:3f4d6b32e26703c6082839234f43769d5046b3ac7c910033911d1e71d8cd630a

LABEL org.opencontainers.image.authors="Luke Skywalker" \
      org.opencontainers.image.source="https://github.com/yodashut/force-crystal"

RUN apk add --no-cache bash

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
