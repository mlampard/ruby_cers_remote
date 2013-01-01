require 'socket'
require 'rexml/document'
require 'base64'

class CersDevice

  def initialize(host,mac,name,deviceid,version)
    @host = host
    @mac = mac
    @name = name
    @deviceid = deviceid
    @version = version
    @cmdlist = Hash.new()
  end

  def dig_tv 
      send_ircc(@cmdlist["Input"]) 
      send_ircc(@cmdlist["Digital"])
  end
  
  def hdmi_1
    send_ircc_mdf(2, 26, 90)
  end

  def hdmi_2
    send_ircc_mdf(2, 26, 91)
  end

  def hdmi_3
    send_ircc_mdf(2, 26, 92)
  end

  def hdmi_4
    send_ircc_mdf(2, 26, 93)
  end

  def sony_register
  	response = http_request("GET","/cers/api/register?name=#{@name}&registrationType=initial&deviceId=#{@deviceid}",["Connection: Close"]){ |socket| socket.read }
  end

  def sony_sysinfo
  	response = http_request("GET","/cers/api/getSystemInformation",["Connection: Close"]){ |socket| socket.read }	  
	puts response
  end

  def sony_sysstatus
  	response = http_request("GET","/cers/api/getStatus?deviceId=#{@deviceid}",["Connection: Close"]){ |socket| socket.read }	  
	puts response
  end
  
  def get_remote_command_list
    response = http_request("GET","/cers/api/getRemoteCommandList",["Connection: close"]){ |socket| socket.read }
    xml = REXML::Document.new(response)
    xml.elements.first.elements.map do |command|
      name = command.to_s[/name\=\'(.*)\'\ type/,1]
      type = command.to_s[/type\=\'(.*)\'\ /,1]
      cmd = command.to_s[/value\=\'(.*)\'\/\>/,1]
      
      if ("#{type}" == "ircc") then 
        @cmdlist["#{name}"] = "#{cmd}"
      end        
    end
    return @cmdlist
  end

  # return the command string associated with name
  def get_remote_command (name)
  	return @cmdlist["#{name}"]
  end


  def send_ircc_mdf(manu,device,function)
    payload = [0, 0, 0, manu, 0, 0, 0, device, 0, 0, 0, function, 3]
    encoded = Base64.encode64(payload.map{|i| i.chr}.join)[0...-1] #no trailing \n
    send_ircc(encoded)
  end

  def send_ircc(ircc = "AAAAAQAAAAEAAABgAw==")
   
    body = <<-HTTP_POST_BODY
<?xml version="1.0"?>
<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" s:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/">
  <s:Body>
    <u:X_SendIRCC xmlns:u="urn:schemas-sony-com:service:IRCC:1">
      <IRCCCode>#{ircc}</IRCCCode>
    </u:X_SendIRCC>
  </s:Body>
</s:Envelope>
HTTP_POST_BODY
    body.gsub!(/\n/,"\r\n")
    puts "body length #{body.bytesize}"
    http_request("POST","/IRCC",[
      'SOAPAction: "urn:schemas-sony-com:service:IRCC:1#X_SendIRCC"',
      'Content-Type: text/xml; charset=utf-8',
      "Content-Length: #{body.bytesize}"
    ],body)
  end


  protected


  def headers(custom_headers = [])
    [
      "Host: #{@host}:80",
      "User-Agent: LinuxRemote/#{@version} Ruby " + RUBY_PLATFORM + " " + RUBY_VERSION ,
      "X-CERS-DEVICE-INFO: "+RUBY_PLATFORM,
      "X-CERS-DEVICE-ID: #{@deviceid}"
       
    ] + custom_headers
  end

  def http_request(method,path,custom_headers,body = nil)
    header_str = headers(custom_headers).join("\r\n")
    req  = "#{method} #{path} HTTP/1.1\r\n#{header_str}\r\n\r\n"
    req += "#{body}" if body

    puts "== CersDevice#send_request ===="
    puts req
    puts "== ===="

    socket = TCPSocket.new(@host,80)
    socket.write(req)

    begin
      return yield socket if block_given?
    ensure
      socket.close
    end
  end

end
