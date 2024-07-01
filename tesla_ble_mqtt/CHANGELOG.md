<!-- https://developers.home-assistant.io/docs/add-ons/presentation#keeping-a-changelog -->

## X.X.X

### Breaking change & Upgrade Instruction
- Cut & Paste your current vin to vin_list
- Cut & Paste your current mac_addr to mac_addr_list

### Changed
- Added support for multi-cars
- Added toggle to enable or disable vehicule detection

## 0.0.10f

### Changed

- **WARNING**: Now supports 3 VINS. You will need to adjust configuration (VIN1/2/3 & BLE MAC)
- **WARNING**: Presence detection only works for VIN1
- Rework project files structure
- Improve logging

## 0.0.9

### Changed

- Fixed useless tesla-control retries

## 0.0.8b

### Changed

- The project has moved to an open source organisation "tesla-local-control". Please update the repo in HA to: https://github.com/tesla-local-control/tesla-local-control-addon

## 0.0.8a

### Changed

- Updated doc for MAC addresses config

## 0.0.8

### Changed

- [Standalone] Fix broken deployment introduced in 0.0.7
- [Standalone] Add colored logging based on log level

## 0.0.7a

### Changed

WARNING: broken for standalone deployment, stay on 0.0.6
OK for HA Addon

- logging msg adjustments & fix logic for log.debug
- logging add logic for log.debug to properly work

## 0.0.7

### Changed

WARNING: broken for standalone deployment, stay on 0.0.6
OK for HA Addon

- Bump to latest updates from tesla_ble_mqtt_docker
- Improve HA logging and error management
- Add FR translation
- Fix auto climate command

## 0.0.6

### Changed

- Fix typo
- Harmonize docs

## 0.0.5

### Changed

- Fix extension stopping at first MQTT listening
- Update logging and documentation
- Improve pairing procedure doc and logging
- Improve HA entities classification
- Cleanup

## 0.0.4

### Changed

- Fix periodicity of BLE discovery (to cope with HA limits)
- Fix set-amps for current above 5A

## 0.0.3

### Changed

- Bump sh content to match iainbullock's developments in separate github: https://github.com/iainbullock/tesla_ble_mqtt_docker
- Enable presence discovery in home-assistant directly

## 0.0.2

### Changed

- Bump sh content to v1.0.14 https://github.com/iainbullock/tesla_ble_mqtt_docker


## 0.0.1

### Changed

- Initial dev version based on https://github.com/iainbullock/tesla_ble_mqtt_docker
- WARN: standalone not tested
