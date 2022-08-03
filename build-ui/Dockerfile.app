FROM node:lts-alpine

RUN apk add gettext
RUN npm install -g http-server
RUN echo -e "#!/bin/sh\n" \
  "envsubst < /app/assets/rgw_admin_ops.config.json.tpl > /app/assets/rgw_admin_ops.config.json\n" \
  "http-server /app/\n" > /usr/bin/entrypoint.sh
RUN chmod +x /usr/bin/entrypoint.sh

WORKDIR /app
COPY ./ .

EXPOSE 8080
ENTRYPOINT [ "/usr/bin/entrypoint.sh" ]
