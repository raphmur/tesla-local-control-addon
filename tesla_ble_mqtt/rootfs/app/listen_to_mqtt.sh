#!/bin/ash

listen_to_mqtt() {
 bashio::log.info "Connecting to MQTT server; subscribe topics tesla_ble/+ and homeassistant/status"
 mosquitto_sub --nodelay -c -i tesla_ble_mqtt -q 1 -h $MQTT_IP -p $MQTT_PORT -u "$MQTT_USER" -P "$MQTT_PWD" -t tesla_ble/+ -t homeassistant/status -F "%t %p" | \
  while read -r payload
  do
   topic=$(echo "$payload" | cut -d ' ' -f 1)
   msg=$(echo "$payload" | cut -d ' ' -f 2-)
   bashio::log.green "Received MQTT message: $topic $msg"
   case $topic in
    tesla_ble/config)
     bashio::log.green "Configuration $msg requested"
     case $msg in
      generate_keys)
       bashio::log.green "Generating the private key"
       openssl ecparam -genkey -name prime256v1 -noout > /share/tesla_ble_mqtt/private.pem
       cat /share/tesla_ble_mqtt/private.pem
       bashio::log.green "Generating the public key"
       openssl ec -in /share/tesla_ble_mqtt/private.pem -pubout > /share/tesla_ble_mqtt/public.pem
       cat /share/tesla_ble_mqtt/public.pem
       bashio::log.green "KEYS GENERATED. Next:
       1/ Remove any previously deployed BLE keys from vehicle before deploying this one
       2/ Wake the car up with your Tesla App
       3/ Push the button 'Deploy Key'";;
      deploy_key)
       bashio::log.yellow "Deploying public key to vehicle"
        send_key;;
      *)
       bashio::log.red "Invalid Configuration request. Topic: $topic Message: $msg";;
     esac;;

    tesla_ble/command)
     bashio::log.green "Command $msg requested"
     case $msg in
       wake)
        bashio::log.green "Waking Car"
        send_command "-domain vcsec $msg";;
       trunk-open)
        bashio::log.green "Opening Trunk"
        send_command $msg;;
       trunk-close)
        bashio::log.green "Closing Trunk"
        send_command $msg;;
       charging-start)
        bashio::log.green "Start Charging"
        send_command $msg;;
       charging-stop)
        bashio::log.green "Stop Charging"
        send_command $msg;;
       charge-port-open)
        bashio::log.green "Open Charge Port"
        send_command $msg;;
       charge-port-close)
        bashio::log.green "Close Charge Port"
        send_command $msg;;
       climate-on)
        bashio::log.green "Start Climate"
        send_command $msg;;
       climate-off)
        bashio::log.green "Stop Climate"
        send_command $msg;;
       flash-lights)
        bashio::log.green "Flash Lights"
        send_command $msg;;
       frunk-open)
        bashio::log.green "Open Frunk"
        send_command $msg;;
       honk)
        bashio::log.green "Honk Horn"
        send_command $msg;;
       lock)
        bashio::log.green "Lock Car"
        send_command $msg;;
       unlock)
        bashio::log.green "Unlock Car"
        send_command $msg;;
       windows-close)
        bashio::log.green "Close Windows"
        send_command $msg;;
       windows-vent)
        bashio::log.green "Vent Windows"
        send_command $msg;;
       *)
        bashio::log.red "Invalid Command Request. Topic: $topic Message: $msg";;
      esac;;

    tesla_ble/charging-set-amps)
     bashio::log.green "Set Charging Amps to $msg requested"
     # https://github.com/iainbullock/tesla_ble_mqtt_docker/issues/4
	 if [ $msg -gt 4 ]; then
	  bashio::log.green "Set amps"
      send_command "charging-set-amps $msg"
	 else
      bashio::log.green "First Amp set"
      send_command "charging-set-amps $msg"
      sleep 1
      bashio::log.green "Second Amp set"
      send_command "charging-set-amps $msg"
	 fi
	 ;;

    tesla_ble/climate-set-temp)
     bashio::log.green "Set Climate Temp to $msg requested"
     send_command "climate-set-temp $msg";;

    tesla_ble/seat-heater)
     bashio::log.green "Set Seat Heater to $msg requested"
     send_command "seat-heater $msg";;

    tesla_ble/auto-seat-and-climate)
     bashio::log.green "Start Auto Seat and Climate"
     send_command "auto-seat-and-climate LR on";;

    tesla_ble/charging-set-limit)
     bashio::log.green "Set Charging limit to $msg requested"
     send_command "charging-set-limit $msg";;
     
    tesla_ble/heated_seat_left)
     bashio::log.green "Set Seat heater to front-left $msg requested"
     send_command "seat-heater front-left $msg";;
     
    tesla_ble/heated_seat_right)
     bashio::log.green "Set Seat heater to front-right $msg requested"
     send_command "seat-heater front-right $msg";;

    homeassistant/status)
     # https://github.com/iainbullock/tesla_ble_mqtt_docker/discussions/6
     bashio::log.green "Home Assistant is stopping or starting, re-running auto-discovery setup"
     setup_auto_discovery;;

    *)
     bashio::log.red "Invalid MQTT topic. Topic: $topic Message: $msg";;
   esac
  done
}
