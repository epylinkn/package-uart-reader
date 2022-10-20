# UART Reader Demo

While info-beamer OS (from version 10) has support for GPIO,
Raspberry Pi's can feel pretty limited for integrating with sensors.
Also, finding and integrating libraries for new sensors into info-beamer OS is time consuming.

This package demonstrates reading comma-delimited values sent from another microcontroller -- e.g. Teensy, Arduino or ESP board.

For example:
- reading any analog sensor (the Pi has no analog inputs!)

TODO: Add Wiring Diagram

### node.json file

This package only has a single configuration option named `pin`.
The follow snippet shows the complete
`node.json` file ([reference documentation](https://info-beamer.com/doc/package-reference#nodejson)).

```json
{
    "name": "UART Reader Demo",
    "permissions": {
        "serial": "yes"
    },
    ...
}
```

It specifies that this node wants access to 
[serial](https://info-beamer.com/doc/package-reference#nodepermissions).

### service file

The package service, bundled as the file `service` in this package,
looks like this:

```python
from hosted import node, config
from time import sleep
import serial

config.restart_on_update()

ser = serial.Serial("/dev/ttyS0", 115200, timeout=0.5)
ser.read(ser.inWaiting())                  # clear buffer
while True:
    received_data = ser.readline()        # read serial (Serial.println(<0-1024>))
    if received_data == '':
        continue

    data = received_data.split(",")

    try:
        if data[0] == 'state':
            node.send('/state:%d' % int(data[1]))      # int measurement!
        else:
            pass # unrecognized message; no-op
    except:
        continue

    sleep(0.03)
```

This file is executed on any device you install this package on. It
runs forever and is automatically restarted by the info-beamer OS
if it terminates for any reason.
The code imports the
[info-beamer package sdk](https://github.com/info-beamer/package-sdk)
from `hosted.py`. The `config` class will automatically be populated with
the configuration values set by the user.

The `config.restart_on_update()` line tells the package sdk to
automatically restart the service every time the configuration changes.
So if the user changes the PIN value from 18 to (for example) 17, the
Python process will exit and is automatically restarted by the
info-beamer OS.

Inside the loop we listen for Serial messages. If a message is read,
we parse it and immediately send this value to the
running info-beamer code in `node.lua` (see below).
The `node.send` call internally sends a UDP packet
to the info-beamer process with the following content assuming this
package is the top-level node (/root) in your setup:

```
/root/state:0
```
or
```
/root/state:1
```

### node.lua

The [util.data_mapper](https://info-beamer.com/doc/info-beamer#utildatamapperroutingtable)
receives incoming UDP packets (remember we send them in the package service above)
and decides how to react the them. The value `state` matches to the `node.send` call
from above.
