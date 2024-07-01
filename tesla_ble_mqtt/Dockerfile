ARG BUILD_FROM
FROM $BUILD_FROM as builder

RUN apk add --no-cache go git

# install Tesla Go packages
RUN git clone https://github.com/teslamotors/vehicle-command.git /vehicle-command
WORKDIR /vehicle-command
RUN go get ./... && \
  go build ./... && \
  go install ./...

FROM $BUILD_FROM

COPY --from=builder /root/go/bin/tesla-control /usr/bin/

# install dependencies
RUN apk add --no-cache \
  bluez \
  bluez-deprecated \
  openssl \
  mosquitto-clients

# Copy data for add-on
COPY app /app/
RUN chmod a+x /app/run.sh
RUN sed -i 's|#!/bin/ash|#!/command/with-contenv bashio|' /app/run.sh

CMD [ "/app/run.sh" ]
