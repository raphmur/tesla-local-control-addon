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
  SEND_CMD_RETRY_LOOP_DELAY="$(bashio::config 'send_cmd_retry_loop_delay')"; export SEND_CMD_RETRY_LOOP_DELAY
  TESLA_PRESENCE_LOOP_DELAY="$(bashio::config 'tesla_presence_loop_delay')"; export TESLA_PRESENCE_LOOP_DELAY
  DEBUG="$(bashio::config 'debug')"; export DEBUG
fi

bashio::log.cyan "tesla_ble_mqtt_docker by Iain Bullock 2024 https://github.com/iainbullock/tesla_ble_mqtt_docker"
bashio::log.cyan "Inspiration by Raphael Murray https://github.com/raphmur"
bashio::log.cyan "Instructions by Shankar Kumarasamy https://shankarkumarasamy.blog/2024/01/28/tesla-developer-api-guide-ble-key-pair-auth-and-vehicle-commands-part-3"

bashio::log.green "Configuration Options are:
  TESLA_VIN=$TESLA_VIN
  BLE_MAC=$BLE_MAC
  MQTT_IP=$MQTT_IP
  MQTT_PORT=$MQTT_PORT
  MQTT_USER=$MQTT_USER
  MQTT_PWD=Not Shown
  SEND_CMD_RETRY_LOOP_DELAY=$SEND_CMD_RETRY_LOOP_DELAY
  TESLA_PRESENCE_LOOP_DELAY=$TESLA_PRESENCE_LOOP_DELAY"

if [ ! -d /share/tesla_ble_mqtt ]
then
    mkdir /share/tesla_ble_mqtt
else
    bashio::log.yellow "/share/tesla_ble_mqtt already exists, existing keys can be reused"
fi


send_command() {
 for i in $(seq 5); do
  bashio::log.yellow "Attempt $i/5"
  set +e
  tesla-control -ble -vin $TESLA_VIN -key-name /share/tesla_ble_mqtt/private.pem -key-file /share/tesla_ble_mqtt/private.pem $1
  EXIT_STATUS=$?
  set -e
  if [ $EXIT_STATUS -eq 0 ]; then
    bashio::log.green "Ok"
    break
  else
    bashio::log.red "Error calling tesla-control, exit code=$EXIT_STATUS - will retry in $SEND_CMD_RETRY_LOOP_DELAY seconds"
    sleep $SEND_CMD_RETRY_LOOP_DELAY
  fi
 done
}

send_key() {
 for i in $(seq 5); do
  bashio::log.yellow "Attempt $i/5"
  set +e
  tesla-control -ble -vin $TESLA_VIN add-key-request /share/tesla_ble_mqtt/public.pem owner cloud_key
  EXIT_STATUS=$?
  set -e
  if [ $EXIT_STATUS -eq 0 ]; then
    bashio::log.yellow "KEY SENT TO VEHICLE: PLEASE CHECK YOU TESLA'S SCREEN AND ACCEPT WITH YOUR CARD"
    break
  else
    bashio::log.red "COULD NOT SEND THE KEY. Is the car awake and sufficiently close to the bluetooth device?"
    sleep $SEND_CMD_RETRY_LOOP_DELAY
  fi
 done 
}

listen_to_ble() {
 bashio::log.green "Listening to BLE"
 set +e
 bluetoothctl --timeout 5 scan on | grep $BLE_MAC
 EXIT_STATUS=$?
 set -e
 if [ $? -eq 0 ]; then
   bashio::log.green "$BLE_MAC presence detected"
   mosquitto_pub --nodelay -h $MQTT_IP -p $MQTT_PORT -u "$MQTT_USER" -P "$MQTT_PWD" -t tesla_ble/binary_sensor/presence -m ON
 else
   bashio::log.yellow "$BLE_MAC presence not detected or issue in command, retrying now"
   mosquitto_pub --nodelay -h $MQTT_IP -p $MQTT_PORT -u "$MQTT_USER" -P "$MQTT_PWD" -t tesla_ble/binary_sensor/presence -m OFF
 fi
}

bashio::log.green "Sourcing functions"
. /app/listen_to_mqtt.sh
. /app/discovery.sh

bashio::log.green "Setting up auto discovery for Home Assistant"
setup_auto_discovery

bashio::log.green "Connecting to MQTT to discard any unread messages"
mosquitto_sub -E -i tesla_ble_mqtt -h $MQTT_IP -p $MQTT_PORT -u $MQTT_USER -P $MQTT_PWD -t tesla_ble/+

ble_listening_loop() {

 bashio::log.green "Initializing BLE scanning loop for car presence"

 while :
 do
   bashio::log.green "Launch BLE scanning for car presence every $TESLA_PRESENCE_LOOP_DELAY"
   listen_to_ble
   sleep $TESLA_PRESENCE_LOOP_DELAY
  fi
 done

}

ble_listening_loop &

echo "Entering main listening MQTT loop"

while true
do
 set +e
 listen_to_mqtt
done
