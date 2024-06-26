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
  bash \
  openssl \
  bluez \
  mosquitto-clients \
  python3

# Python 3 HTTP Server serves the current working dir
WORKDIR /data

# Copy data for add-on
COPY rootfs /
RUN chmod a+x /app/run.sh

CMD [ "/app/run.sh" ]
