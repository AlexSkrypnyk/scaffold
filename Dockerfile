# hadolint global ignore=DL3018
FROM alpine:3

LABEL org.opencontainers.image.authors="Your Name" \
      org.opencontainers.image.source="https://github.com/yournamespace/yourproject"

RUN apk add --no-cache bash

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
