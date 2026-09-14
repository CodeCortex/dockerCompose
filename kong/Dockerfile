FROM kong/kong-gateway:3.15.0.5

USER root

COPY plugins/custom-auth /usr/local/share/lua/5.1/kong/plugins/custom-auth

USER kong




# used in composed yml if docker is used


# kong:
  # build:
  #   context: ./kong
  #   dockerfile: Dockerfile

  # container_name: kong

  # depends_on:
  #   - authService
  #   - expenseService
  #   - userservice

  # environment:
  #   KONG_DATABASE: "off"
  #   KONG_DECLARATIVE_CONFIG: /kong/declarative/kong.yml
  #   KONG_PLUGINS: bundled,custom-auth
  #   KONG_PROXY_ACCESS_LOG: /dev/stdout
  #   KONG_PROXY_ERROR_LOG: /dev/stderr
  #   KONG_ADMIN_ACCESS_LOG: /dev/stdout
  #   KONG_ADMIN_ERROR_LOG: /dev/stderr
  #   KONG_ADMIN_LISTEN: 0.0.0.0:8001

  # volumes:
  #   - ./kong.yml:/kong/declarative/kong.yml:ro

  # ports:
  #   - "8000:8000"
  #   - "8001:8001"