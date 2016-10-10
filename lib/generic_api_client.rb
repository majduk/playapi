class GenericAPIClient
  require 'net/http'
  require 'net/https'
  require 'uri'

  class HTTPResponseException < StandardError
    attr_reader :response
    
    def initialize(response)
      @response = response
    end
    
    def inspect
      "#<#{self.class} response=#{response.inspect}>"
    end
    
    def to_s
      "#{self.class}::#{response.class}"
    end         
  end

  def self.enabled?
    return (not config.blank?)
  end

  protected
  def self.return_nil_on_error(response)
       if response.kind_of? Net::HTTPSuccess
          json={}
          json=JSON.parse(response.body) unless response.body.blank?
          json
       else       
          nil
       end  
  end

  def self.raise_exception_on_error(response)
    
       if response.kind_of? Net::HTTPSuccess
          json={}
          JSON.parse(response.body) unless response.body.blank?
       else       
          raise HTTPResponseException.new(response)
       end    
  end
      
  def self.execute(http_method,path,params = nil,body=nil,&block)
     require_configured 
     appkey=config[:appkey]
     base_uri=config[:uri]
     uri_params=config[:uri_params]
     auth=config[:auth]
     qstring="?resformat=json"
     qstring+="&" + params.to_query unless params.blank?
     qstring+="&" + "appkey=" + appkey unless appkey.blank?
     qstring+="&" + uri_params.to_query unless uri_params.blank?          
     uri = URI.parse( base_uri + path + qstring)
     headers={}
     if http_method==:post or http_method==:put and not body.nil? 
      content_type = 'application/json' 
      content_type = config[:content_type] unless config[:content_type].blank?
      headers['Content-Type'] = content_type
     end     
     if uri.scheme == 'https'       
         verify_mode = OpenSSL::SSL::VERIFY_PEER
         cert_pem = File.read(auth[:cert]) unless auth.blank?
         key_pem = File.read(auth[:key]) unless auth.blank?
         if cert_pem
            cert = OpenSSL::X509::Certificate.new(cert_pem)
            key = OpenSSL::PKey::RSA.new(key_pem)
         end
         http = Net::HTTP.new(uri.host, uri.port, :use_ssl => true, :verify_mode => verify_mode, :cert => cert, :key => key )                           
     else
       http = Net::HTTP.new(uri.host, uri.port)
       headers[auth[:name]]=auth[:value] unless auth.blank? or auth[:name].blank? or auth[:value].blank?   
     end

     request = case http_method 
      when :post 
        Net::HTTP::Post.new(uri.request_uri, initheader = headers) 
      when :put 
        Net::HTTP::Put.new(uri.request_uri, initheader = headers) 
      when :get 
        Net::HTTP::Get.new(uri.request_uri, initheader = headers)
      when :delete 
        Net::HTTP::Delete.new(uri.request_uri, initheader = headers)
      else
        raise "Undefined method #{http_method}"  
     end

     request.body=body unless body.nil?
     response = http.request(request)     
     Rails.logger.debug("#{self} #{http_method} #{uri.inspect} #{request.body} response #{response.inspect} #{response.body}")      
          
     if block_given?
       result=yield request,response 
     else
       result=return_nil_on_error(response)   
     end
   
  end
  
  
  def self.get(path,params = nil,&block)
    execute(:get,path,params,nil,&block)
  end
    
  def self.post(path,body,params = nil,&block)
    execute(:post,path,params,body,&block)
  end    

  def self.put(path,body,params = nil)
    execute(:put,path,params,body,&block)
  end 

  def self.delete(path,params = nil,&block)
    execute(:delete,path,params,nil,&block)
  end
  
  def self.require_configured
    conf_name="#{self}".underscore.to_sym
    raise Exception.new "Unconfigured: #{conf_name}" unless enabled?    
  end    
    
  def self.config
    return APP_CONFIG["#{self}".underscore.to_sym]
  end  

end
