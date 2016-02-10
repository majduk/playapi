require 'generic_api_client'

class LocationClient

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
     return get("",qparams) do |request,response|
        return_nil_on_error(response)
     end       
  end
end
