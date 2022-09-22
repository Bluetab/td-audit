### Minimal runtime image based on alpine:3.13
ARG RUNTIME_BASE=alpine:3.13

FROM ${RUNTIME_BASE}

LABEL maintainer="info@truedat.io"

ARG MIX_ENV=prod
ARG APP_VERSION
ARG APP_NAME

WORKDIR /app

COPY _build/${MIX_ENV}/*.tar.gz ./

# grab su-exec for easy step-down from root
RUN apk --no-cache add ncurses-libs openssl bash ca-certificates libstdc++ tzdata 'su-exec>=0.2' && \
    rm -rf /var/cache/apk/* && \
    tar -xzf *.tar.gz && \
    rm *.tar.gz && \
    adduser -h /app -D app && \
    chown -R app: /app

# Run entrypoint as root and step down to app using su-exec

ENV APP_NAME ${APP_NAME}
ENTRYPOINT ["/bin/bash", "-c", "bin/start.sh"]
