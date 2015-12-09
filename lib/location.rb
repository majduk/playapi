class LocationClient
  require 'net/http'
  require 'net/https'
  require 'uri'

  def self.enabled?
    return (not config.blank?)
  end
  
  def self.query(msisdn)
     raise LocationClientNotEnabled unless enabled?
     appkey=config[:appkey]
     base_uri=config[:uri]
     auth=config[:auth]
     params={
      :requestedAccuracy=>2,
      :acceptableAccuracy=>5,
      :responseTime=>3,
      :tolerance=>"LowDelay",
      :maximumAge=>100, 
     }
     params.merge! config[:params] unless  config[:params].blank?
     uri = URI.parse( base_uri + "?resformat=json&appkey=" + appkey + "&address=" + msisdn + "&" + params.to_query)
     Rails.logger.debug("LocationClient #{uri.inspect}")
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
     Rails.logger.debug("Location API returned #{response.body}")      
     
     if response.kind_of? Net::HTTPSuccess
        json=JSON.parse(response.body)
        res=json["terminalLocationList"]["terminalLocation"][0]["currentLocation"]
     else 
        res=nil
     end
     
     Rails.logger.debug("LocationClient returned #{res.inspect}")
     return res  
  end
  
  protected
  def self.config
    return APP_CONFIG[:location_api]
  end
  
end
