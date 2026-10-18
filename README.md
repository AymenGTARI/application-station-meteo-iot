# IoT Weather Station with Mobile App

An end-to-end IoT weather station: an ESP32 reads environmental sensors, publishes the data over MQTT, Node-RED validates and forwards it to ThingSpeak, and a Flutter mobile app displays real-time and historical data.

## Features

- Real-time measurements: temperature, humidity, pressure, luminosity, wind speed and direction, and rain detection
- Local messaging with an MQTT broker (Mosquitto) on the local network
- Data processing and forwarding with Node-RED
- Cloud storage and charts on ThingSpeak, accessed through its REST API
- Flutter mobile app with real-time view, history (24 h, 7 days, 30 days, 1 year), configurable alerts, and offline mode
- Firebase Authentication for user login
- Bidirectional communication between the app and ThingSpeak, with local caching and automatic synchronization

## Architecture

```
[BME280, BH1750, anemometer, rain sensor]
              |  I2C / analog / digital
              v
          [ESP32]  --- MQTT (Mosquitto broker, local network) --->  [Node-RED]
                                                                        |  validation, merging,
                                                                        |  REST API (HTTP)
                                                                        v
                                                                  [ThingSpeak Cloud]
                                                                        ^
                                                                        |  HTTP GET (cache + sync)
                                                                  [Flutter mobile app]  <--> [Firebase Auth]
```

## Hardware

| Component | Role |
|---|---|
| ESP32 | Microcontroller, WiFi, MQTT client |
| BME280 | Temperature, humidity, pressure (I2C) |
| BH1750 | Light intensity (I2C) |
| Anemometer | Wind speed |
| Wind vane | Wind direction |
| Rain sensor | Rain detection |

Wiring details and pin assignments are in `docs/wiring.md` (to be added).

## Software Stack

- **Firmware:** C/C++ with the Arduino IDE
- **Broker:** Eclipse Mosquitto
- **Processing:** Node-RED
- **Cloud:** ThingSpeak
- **Mobile app:** Flutter (Dart), Firebase Authentication

## Getting Started

### 1. Firmware (ESP32)

1. Install the ESP32 board package in the Arduino IDE.
2. Install the sensor libraries used by the sketch (for example the BME280 and BH1750 libraries) and an MQTT client library.
3. Open `firmware/weather_station/weather_station.ino`.
4. Set your WiFi credentials, the MQTT broker address, and the topic names in `config.h`.
5. Upload the sketch to the ESP32.

### 2. MQTT broker

Install Mosquitto on a machine in the local network and allow connections from the ESP32 and Node-RED:

```bash
sudo apt install mosquitto mosquitto-clients
mosquitto_sub -h localhost -t "weather/#" -v   # check that messages arrive
```

### 3. Node-RED flow

1. Install Node-RED and start it.
2. Import `node-red/flows.json` through the menu (Import).
3. Configure the MQTT broker node and the ThingSpeak HTTP request node with your Write API Key.
4. Deploy the flow.

### 4. ThingSpeak

1. Create a channel with one field per measurement.
2. Copy the Write API Key (used by Node-RED) and the Read API Key (used by the app).

### 5. Mobile app

```bash
cd app
flutter pub get
flutter run
```



## Project Structure

```
.
├── firmware/          # ESP32 sketch
├── node-red/          # Node-RED flow export
├── app/               # Flutter mobile application
├── docs/              # Wiring diagrams and documentation
└── README.md
```

## Screenshots
<img width="430" height="867" alt="Capture d&#39;écran 2026-09-03 220022" src="https://github.com/user-attachments/assets/fa96476e-afcd-4e7a-aada-08a2a13cda34" />


<img width="551" height="672" alt="Capture d&#39;écran 2026-09-20 204350" src="https://github.com/user-attachments/assets/38c5396c-b440-4415-98a2-2d7da3f47917" />


## Author

**Aymen Gtari**, electrical and industrial computing engineering student specialized in embedded systems.

