require 'generic_api_client'

class MnpClient
  def self.query(msisdn)
    qparams={
      "output"=>"json",
      "show_imsi"=>"true",
      "target" => "#{msisdn}"
    }
    uri = URI.parse( base_uri + "?output=json&show_imsi=true&appkey=" + appkey + "&target=" + msisdn)
    result=get("",qparams) do |request,response|
        return_nil_on_error(response)
    return result  
  end
end
