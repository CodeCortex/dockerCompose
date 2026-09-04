FROM kong/kong-gateway:3.15.0.5

USER root

COPY plugins/custom-auth /usr/local/share/lua/5.1/kong/plugins/custom-auth

USER kong