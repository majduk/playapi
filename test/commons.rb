require 'minitest/autorun'
require 'uri'
require 'generic_api_client'

module Net
  class HTTPResponse
    alias old_body= body=
    def body=(b)
      @body=b
    end
    alias old_body body
    def body
      @body
    end
  end
  class HTTP < Protocol
    @@response=nil
    @@last_request_path=nil
    @@timeout=false

    def self.respond_ok(body=nil)
      @@response=Net::HTTPSuccess.new("1.1",200,"OK")
      @@response.body=body
    end    

    def self.respond_internal_error(body=nil)
      @@response=Net::HTTPInternalServerError.new("1.1",500,"Server Error")
      @@response.body=body
    end    

    def self.respond_gateway_timeout()
      @@response=Net::HTTPGatewayTimeOut.new("1.1",504,"Server Error")
    end    

    def self.respond_bad_gateway()
      @@response=Net::HTTPBadGateway.new("1.1",502,"Server Error")
    end    

    def self.respond_bad_request()
      @@response=Net::HTTPBadRequest.new("1.1",400,"Server Error")
    end    

    def self.respond_payment_required()
      @@response=Net::HTTPPaymentRequired.new("1.1",402,"Payment Required")
    end    

    def self.response=(r)
      @@response=r
    end

    def self.trigger_timeout=(t)
      @@timeout=t
    end

    def self.last_request_path
      @@last_request_path
    end

    def self.last_request_path_reset
      @@last_request_path=nil
    end

    alias old_request request
    def request(req, body = nil, &block)
      @@last_request_path = req.path
      raise Net::ReadTimeout.new if @@timeout
      return @@response
    end  
  end
end

class Hash
  alias old_with_indifferent_access with_indifferent_access if Hash.method_defined? :with_indifferent_access
  def with_indifferent_access
    return self
  end
end

class Rails
  def self.logger
    self
  end
  def self.debug(params)
    #puts params
  end
  def self.warn(params)
    debug params
  end
end

class TestSuiteConfig
    @@setted_up = false
    def self.load
      Net::HTTP.trigger_timeout=false
      Net::HTTP.last_request_path_reset
      Net::HTTP.respond_ok
      return if @@setted_up
       GenericAPIClient.const_set(:APP_CONFIG, {
        :generic_api_client =>{           
          :appkey => "appkey",
          :uri => "http://apihost:80/uri"
        },
        :ussd_auth_client =>{           
          :appkey => "appkey",
          :uri => "http://apihost:80/uri"
        },
        :vcmp_payments_client =>{           
          :appkey => "appkey",
          :uri => "http://apihost:80/uri",
          :apitype =>  "custom",
          :buyChannel => "PREMIUM_WAP",
          :buyOptionCode => "USLUGA_PREMIUM",
          :type => "USLUGA_PREMIUM",    
          :name => "USLUGA_PREMIUM",
          :description => "USLUGA_PREMIUM"
        },
        :mnp_client =>{           
          :appkey => "appkey",
          :uri => "http://apihost:80/uri",
        }
      } )
      @@setted_up=true
    end    

end
