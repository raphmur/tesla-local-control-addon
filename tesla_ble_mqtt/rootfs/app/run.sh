#!/bin/sh

[ -L /command/with-contenv ] \
  && exec /command/with-contenv /usr/bin/bashio /app/run-tesla-local-control-main.sh \
  || exec /bin/bash /app/run-tesla-local-control-main.sh
