This script will configure your Canon camera to auto-focus, take a photo every x seconds and will also record the temperature of the lens, CCD and battery to a log file.
The script can be run in Endless mode until the battery or storage space runs out.

This script was built for my work on the HAPPy (High Altitude Photo Project) balloon project at http://happycapsule.com – a high altitude balloon project which aims to photograph the earth from the stratosphere.

HAPPy Intervalometer Features:
– HAPPy logging – write temperature (C), battery voltage (mV) and timestamp data to log file.
– Log files written every time the shutter clicks.
– Log files located in CHDK/LOGS/
– Endless mode – will keep taking photos until battery dies or card is full.
– Turn off the display a given number of frames after starting to conserve battery.
– Auto focus and expose for each photo.

As I build scripts to graph and process the log data, I will post them here.

CSV header columns generated in the log files
Photo Number,Date,Time,Battery Voltage,Lens Temp,CCD Temp,Battery Temp,Elapsed Time


![alt text](https://github.com/zinkwazi/HAPPy-CHDK/blob/main/70k.jpg?raw=true)
