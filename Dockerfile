# Web (HTML5) build of Galaxy, served by nginx. Coolify builds this from the
# repo root with the "Dockerfile" build pack - see docs/DEPLOY_COOLIFY.md.
#
# Stage 1 runs Defold's command-line builder (bob.jar) to bundle the game for
# the browser. Native extensions (websocket) are compiled remotely
# by Defold's public build server, so the build needs outbound internet.

# Match the editor you develop with (Defold -> About). 1.13.x bundles JDK 25.
ARG DEFOLD_VERSION=1.13.1

FROM eclipse-temurin:25-jdk AS build
ARG DEFOLD_VERSION
# Where the browser build connects to Nakama. Set these as build variables in
# Coolify; the defaults only work for a local docker test.
ARG NAKAMA_HOST=127.0.0.1
ARG NAKAMA_PORT=7350
ARG NAKAMA_USE_SSL=0
ARG NAKAMA_SERVER_KEY=defaultkey

# Bob's bundled native tools link against these even when building headless.
RUN apt-get update \
    && apt-get install -y --no-install-recommends libx11-6 libxext6 libxrender1 libxtst6 libxi6 libgl1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /src
ADD https://github.com/defold/defold/releases/download/${DEFOLD_VERSION}/bob.jar /opt/bob.jar
COPY . .

# Overrides game.project's [nakama] section for this build only.
RUN printf '[nakama]\nhost = %s\nport = %s\nuse_ssl = %s\nserver_key = %s\n' \
        "$NAKAMA_HOST" "$NAKAMA_PORT" "$NAKAMA_USE_SSL" "$NAKAMA_SERVER_KEY" > /tmp/deploy.ini \
    && java -jar /opt/bob.jar \
        --platform wasm-web \
        --architectures wasm-web \
        --variant release \
        --archive \
        --settings /tmp/deploy.ini \
        --bundle-output /out \
        resolve build bundle \
    && mv "/out/$(ls /out | head -n 1)" /out/web

FROM nginx:1.29-alpine
# The website that logs players in (see deploy/nginx.conf.template); set
# LARAVEL_URL in Coolify if it isn't https://fig.limited.
ENV LARAVEL_URL=https://fig.limited \
    NGINX_RESOLVER=127.0.0.11
COPY deploy/nginx.conf.template /etc/nginx/templates/default.conf.template
COPY --from=build /out/web /usr/share/nginx/html
EXPOSE 80
