require 'generic_api_client'

class LocationClient  < GenericAPIClient

  def self.query(msisdn)
     qparams={
      :requestedAccuracy=>2,
      :acceptableAccuracy=>5,
      :responseTime=>3,
      :tolerance=>"LowDelay",
      :maximumAge=>100, 
      :address => "#{msisdn}"
     }
     qparams=qparams.merge config[:params] 
     result=get("",qparams) do |request,response|
        raise_exception_on_error(response)
     end
     return result      
  end
end
