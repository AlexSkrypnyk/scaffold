# hadolint global ignore=DL3018
FROM alpine:3@sha256:a2d49ea686c2adfe3c992e47dc3b5e7fa6e6b5055609400dc2acaeb241c829f4

LABEL org.opencontainers.image.authors="Your Name" \
      org.opencontainers.image.source="https://github.com/yournamespace/yourproject"

RUN apk add --no-cache bash

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
