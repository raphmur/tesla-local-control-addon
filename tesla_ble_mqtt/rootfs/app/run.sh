#!/command/with-contenv bashio
#set -e


# read options in case of HA addon. Otherwise, they will be sent as environment variables
if [ -n "${HASSIO_TOKEN:-}" ]; then
  TESLA_VIN="$(bashio::config 'vin')"; export TESLA_VIN
  BLE_MAC="$(bashio::config 'ble_mac')"; export BLE_MAC
  MQTT_IP="$(bashio::config 'mqtt_ip')"; export MQTT_IP
  MQTT_PORT="$(bashio::config 'mqtt_port')"; export MQTT_PORT
  MQTT_USER="$(bashio::config 'mqtt_user')"; export MQTT_USER
  MQTT_PWD="$(bashio::config 'mqtt_pwd')"; export MQTT_PWD
  SEND_CMD_RETRY_DELAY="$(bashio::config 'send_cmd_retry_delay')"; export SEND_CMD_RETRY_DELAY
  DEBUG="$(bashio::config 'debug')"; export DEBUG
fi

# Set log level to debug?
bashio::config.true debug && bashio::log.level debug

bashio::log.cyan "tesla_ble_mqtt_docker by Iain Bullock 2024 https://github.com/iainbullock/tesla_ble_mqtt_docker"
bashio::log.cyan "Inspiration by Raphael Murray https://github.com/raphmur"
bashio::log.cyan "Instructions by Shankar Kumarasamy https://shankarkumarasamy.blog/2024/01/28/tesla-developer-api-guide-ble-key-pair-auth-and-vehicle-commands-part-3"

bashio::log.green "Configuration Options are:"
bashio::log.green TESLA_VIN=$TESLA_VIN
bashio::log.green BLE_MAC=$BLE_MAC
bashio::log.green MQTT_IP=$MQTT_IP
bashio::log.green MQTT_PORT=$MQTT_PORT
bashio::log.green MQTT_USER=$MQTT_USER
bashio::log.green "MQTT_PWD=Not Shown"
bashio::log.green SEND_CMD_RETRY_DELAY=$SEND_CMD_RETRY_DELAY

if [ ! -d /share/tesla_ble_mqtt ]
then
    bashio::log.info SEND_CMD_RETRY_DELAY=$SEND_CMD_RETRY_DELAY
    mkdir /share/tesla_ble_mqtt
else
    bashio::log.debug "/share/tesla_ble_mqtt already exists, existing keys can be reused"
fi


send_command() {
 for i in $(seq 5); do
  bashio::log.notice "Attempt $i/5 to send command"
  set +e
  tesla-control -ble -vin $TESLA_VIN -key-name /share/tesla_ble_mqtt/private.pem -key-file /share/tesla_ble_mqtt/private.pem $1
  EXIT_STATUS=$?
  set -e
  if [ $EXIT_STATUS -eq 0 ]; then
    bashio::log.info "tesla-control send command succeeded"
    break
  else
    bashio::log.error "tesla-control send command failed exit status $EXIT_STATUS. Retrying in $SEND_CMD_RETRY_DELAY"
    sleep $SEND_CMD_RETRY_DELAY
  fi
 done
}

send_key() {
 for i in $(seq 5); do
  bashio::log.notice "Attempt $i/5 to send public key"
  set +e
  tesla-control -ble -vin $TESLA_VIN add-key-request /share/tesla_ble_mqtt/public.pem owner cloud_key
  EXIT_STATUS=$?
  set -e
  if [ $EXIT_STATUS -eq 0 ]; then
    bashio::log.yellow "KEY SENT TO VEHICLE: PLEASE CHECK YOU TESLA'S SCREEN AND ACCEPT WITH YOUR CARD"
    break
  else
    bashio::log.error "tesla-control could not send the key; make sure the car is awake and sufficiently close to the bluetooth device. Retrying in $SEND_CMD_RETRY_DELAY""
    bashio::log.error "Retrying in $SEND_CMD_RETRY_DELAY"
    sleep $SEND_CMD_RETRY_DELAY
  fi
 done
}

PRESENCE_BINARY_SENSOR=OFF
listen_to_ble() {
 PRESENCE_TIMEOUT=5
 bashio::log.info "Listening to BLE for presence"
 set +e
 bluetoothctl --timeout $PRESENCE_TIMEOUT scan on | grep $BLE_MAC
 EXIT_STATUS=$?
 set -e
 if [ $? -eq 0 ]; then
   bashio::log.info "$BLE_MAC presence detected"
   if [ $PRESENCE_BINARY_SENSOR == "OFF" ]; then
     bashio::log.info "Updating topic tesla_ble/binary_sensor/presence ON"
     mosquitto_pub --nodelay -h $MQTT_IP -p $MQTT_PORT -u "$MQTT_USER" -P "$MQTT_PWD" -t tesla_ble/binary_sensor/presence -m ON
     PRESENCE_BINARY_SENSOR=ON
   else
     bashio::log.debug "Topic tesla_ble/binary_sensor/presence already ON"
   fi
 else
   bashio::log.warning "$BLE_MAC presence not detected or issue in command, will retry later"
   if [ $PRESENCE_BINARY_SENSOR == "ON" ]; then
     bashio::log.info "Updating topic tesla_ble/binary_sensor/presence OFF"
     mosquitto_pub --nodelay -h $MQTT_IP -p $MQTT_PORT -u "$MQTT_USER" -P "$MQTT_PWD" -t tesla_ble/binary_sensor/presence -m OFF
     PRESENCE_BINARY_SENSOR=OFF
   else
     bashio::log.debug "Topic tesla_ble/binary_sensor/presence already OFF"
   fi
 fi
}

bashio::log.yellow "Sourcing functions"
. /app/listen_to_mqtt.sh
. /app/discovery.sh

bashio::log.info "Setting up auto discovery for Home Assistant"
setup_auto_discovery

bashio::log.info "Connecting to MQTT to discard any unread messages"
mosquitto_sub -E -i tesla_ble_mqtt -h $MQTT_IP -p $MQTT_PORT -u $MQTT_USER -P $MQTT_PWD -t tesla_ble/+

bashio::log.info "Initialize BLE listening loop counter"
counter=0
bashio::log.info "Entering main MQTT & BLE listening loop"
while true
do
 set +e
 listen_to_mqtt
 if [ -z "$BLE_MAC" ]; then
   ((counter++))
   if [[ $counter -gt 90 ]]; then
    bashio::log.info "Reached 90 MQTT loops (~3min): Launch BLE scanning for car presence"
    listen_to_ble
    counter=0
   fi
 fi
 sleep 2
done
