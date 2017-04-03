class GenericAPIClient
  require 'net/http'
  require 'net/https'
  require 'uri'
  require 'cgi'
  require 'json'

  class HTTPResponseException < StandardError
    attr_reader :response
    
    def initialize(clazz,response)
      @clazz = clazz
      @response = response
    end
    
    def inspect
      "#<#{@clazz} response=#{response.inspect}>"
    end
    
    def to_s
      "#{@clazz}::#{response.class}"
    end         
  end

  def self.enabled?
    return false if config.nil?
    return (not config.empty?)
  end

  protected
  def self.return_nil_on_error(response)
       if response.kind_of? Net::HTTPSuccess
          json={}
          json=JSON.parse(response.body) unless response.body.nil?
          json
       else       
          nil
       end  
  end

  def self.raise_exception_on_error(response)
    
       if response.kind_of? Net::HTTPSuccess
          json={}
          json=JSON.parse(response.body) unless response.body.nil?
          json
       else       
          raise HTTPResponseException.new(self,response)
       end    
  end


  def self.execute(http_method,path,params = nil,body=nil,&block)
     require_configured 
     appkey=config[:appkey]
     raise Exception.new "Unconfigured: #{conf_name}.appkey" if appkey.nil?
     base_uri=config[:uri]
     raise Exception.new "Unconfigured: #{conf_name}.uri" if base_uri.nil?
     uri_params=config[:uri_params]
     auth=config[:auth]
     http_config=config[:http]
     qstring="?resformat=json"
     qstring+="&" + self.to_query(params) unless params.nil?
     qstring+="&" + "appkey=" + appkey unless appkey.nil?
     qstring+="&" + self.to_query(uri_params) unless uri_params.nil?          
     uri = URI.parse( base_uri + path + qstring)
     headers={}
     if http_method==:post or http_method==:put and not body.nil? 
      content_type = 'application/json' 
      content_type = config[:content_type] unless config[:content_type].nil?
      headers['Content-Type'] = content_type
     end  
     if uri.scheme == 'https'       
         verify_mode = OpenSSL::SSL::VERIFY_PEER
         cert_pem = File.read(auth[:cert]) unless auth.nil?
         key_pem = File.read(auth[:key]) unless auth.nil?
         if cert_pem
            cert = OpenSSL::X509::Certificate.new(cert_pem)
            key = OpenSSL::PKey::RSA.new(key_pem)
         end
         http = Net::HTTP.new(uri.host, uri.port, :use_ssl => true, :verify_mode => verify_mode, :cert => cert, :key => key )                           
     else
       http = Net::HTTP.new(uri.host, uri.port)
       headers[auth[:name]]=auth[:value] unless auth.nil? or auth[:name].nil? or auth[:value].nil?   
     end
     unless http_config.nil?
       http_config.keys.each do |http_config_param|
         http.instance_variable_set "@#{http_config_param}", http_config[http_config_param]
       end
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
    raise Exception.new "Unconfigured: #{conf_name}" unless enabled?    
  end    
    
  def self.config
    return APP_CONFIG[conf_name]
  end  

  def self.conf_name
    camel_cased_word="#{self}"
    return camel_cased_word.to_sym unless camel_cased_word =~ /[A-Z-]|::/
    word = camel_cased_word.to_s.gsub(/::/, '/')
    word.gsub!(/([A-Z\d]+)([A-Z][a-z])/,'\1_\2')
    word.gsub!(/([a-z\d])([A-Z])/,'\1_\2')
    word.tr!("-", "_")
    word.downcase!
    return word.to_sym
  end

  def self.to_query(params)
    params.collect do |key, value|
      "#{CGI.escape(key.to_s)}=#{CGI.escape(value.to_s)}"
    end.sort * '&'
  end

end
