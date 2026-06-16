# hadolint global ignore=DL3018
FROM alpine:3@sha256:28bd5fe8b56d1bd048e5babf5b10710ebe0bae67db86916198a6eec434943f8b

LABEL org.opencontainers.image.authors="Your Name" \
      org.opencontainers.image.source="https://github.com/yournamespace/yourproject"

RUN apk add --no-cache bash

COPY entrypoint.sh /usr/local/bin/entrypoint.sh

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
