require "~/cers_device.rb"
require 'macaddr'
require 'green_shoes'
require 'socket'
version = "0.0.1"

@tvs = Hash.new()

remote_name="LinuxRemote"
remote_uid= "uuid:11111111-D7A0-11DD-119C-6D990C3C4520"

paired_device_mac = Mac.addr.gsub!(':','-')

# discover cers capable device on the network via ssdp and return its IP.
def discover_sony
#  ssdp = "M-SEARCH * HTTP/1.1\r\nHost: 239.255.255.250:1900\r\nST: upnp:rootdevice\r\nMan: \"ssdp:discover\"\r\nMX: 2\r\n\r\n\r\n"
  ssdp = "M-SEARCH * HTTP/1.1\r\nHost: 239.255.255.250:1900\r\nST: urn:schemas-sony-com:service:IRCC:1\r\nMan: \"ssdp:discover\"\r\nMX: 2\r\n\r\n\r\n"
  sock = UDPSocket.new
  sock.send(ssdp, 0, '239.255.255.250', 1900)

  rec = sock.recv(1000)
  rec =~ /HTTP\:\/\/(.*)\:/i
  client_ip = "#{$1}"
  rec =~/pa\=\"(.*)\"/i
  @tvs["#{$1}"] = client_ip
  sock.close
  return client_ip
end

tv_ip = discover_sony
#tv_ip = "192.168.2.127"

device = CersDevice.new(tv_ip,paired_device_mac,remote_name,remote_uid,version)

#register the app. Only has to be done once, but multiples are ignored so just do it..
device.sony_register()
#device.hdmi_1
#device.sony_sysinfo()
#device.sony_sysstatus()
 
cmdlist  = device.get_remote_command_list

cmdlist.each {|key,value| puts "have #{key} which is #{value}"}

Shoes.app  :title=>"#{remote_name}", :align=>'center',:height=>600 do
background black
	flow {
	  button "HDMI 1",:width=>100,:height=>25 do device.hdmi_1 end
	  button "HDMI 2",:width=>100,:height=>25  do device.hdmi_2 end
	  button "HDMI 3",:width=>100,:height=>25  do device.hdmi_3 end
	  button "HDMI 4",:width=>100,:height=>25  do device.hdmi_4 end
	  button "TV",:width=>100,:height=>25  do device.dig_tv end
	}
	
	cmdlist.each {|key,value| button "#{key}",:width => 150,:height=>25  do device.send_ircc("#{value}") end}
end
 
