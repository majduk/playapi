class MnpClient
  require 'net/http'
  require 'net/https'
  require 'uri'

  def self.enabled?
    return (not config.blank?)
  end
  
  def self.query(msisdn)
     raise Exception.new "MnpClientNotEnabled" unless enabled?
     appkey=config[:appkey]
     base_uri=config[:uri]
     auth=config[:auth]
    
     uri = URI.parse( base_uri + "?output=json&show_imsi=true&appkey=" + appkey + "&target=" + msisdn)
     Rails.logger.debug("MnpClient #{uri.inspect}")

    if uri.scheme == 'https'       
         verify_mode = OpenSSL::SSL::VERIFY_PEER
         cert_pem = File.read(auth[:cert])
         key_pem = File.read(auth[:key])
         if cert_pem
            cert = OpenSSL::X509::Certificate.new(cert_pem)
            key = OpenSSL::PKey::RSA.new(key_pem)
         end
         http = Net::HTTP.new(uri.host, uri.port, :use_ssl => true, :verify_mode => verify_mode, :cert => cert, :key => key )  
         request = Net::HTTP::Get.new(uri.request_uri)        
    else
       http = Net::HTTP.new(uri.host, uri.port)  
       request = Net::HTTP::Get.new(uri.request_uri,
          initheader = {
            auth[:name]  => auth[:value]
          }              
       )            
    end
    response = http.request(request)     
     
    Rails.logger.debug("MnpClient server returned #{response.body}")      
     
    if response.kind_of? Net::HTTPSuccess
        json=JSON.parse(response.body)
        res=json["api"]["request"]["mnp"]
    else 
        #error returned
        res=nil
    end
     
    Rails.logger.debug("MnpClient returned #{res.inspect}")
    return res  
  end
  
  protected
  def self.config
    return APP_CONFIG[:mnp_api]
  end
  
end
