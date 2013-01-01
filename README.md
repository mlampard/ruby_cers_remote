Ruby cers API for Sony TVs © Luke Mcildoon 2012 - MIT licenced
			     Additions (c) Mike Lampard 2012/2013 

Some ethernet/wifi-enabled Sony TVs have a webserver running on them for remote control from mobile devices. This is a super-simple work-in-progress interface into everything it exposes.

In typical Sony fashion, there's a security system in place that the device has to "pair" with the TV before it can issue commands. However, if you know the MAC address of a paired device, the TV doesn't actually check that the command came from that MAC address, only checking a HTTP header sent in the request.

This does however mean you'll need to do one initial pairing with a mobile device using Sony's "MediaRemote" mobile app, and use the paired device's MAC address when using the CersDevice class.

Example usage:

require "cers_device"
tv_ip = "192.168.0.37"
paired_device_mac = "1c-ab-a7-00-01-3a"

device = CersDevice.new(tv_ip,paired_device_mac)
device.get_remote_command_list
# => [{"name"=>"Confirm", "value"=>"AAAAAQAAAAEAAABlAw==", "type"=>"ircc"}, ... ]

device.send_ircc("AAAAAQAAAAEAAABlAw==") #sends "Confirm" keypress to tv

Commands of type IRCC have a base64-encoded payload, this is just a bytestream of IR codes. Haven't worked out the details of the "url" type commands, may or may not be as simple as they look

...

Mike Lampard:
Added the ability to register a client with the ruby cers api, and added a simple remote control gui (sony.rb) as an example.
