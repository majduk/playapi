require 'generic_api_client'

class MnpClient  < GenericAPIClient
  def self.query(msisdn)
    qparams={
      "output"=>"json",
      "show_imsi"=>"true",
      "target" => "#{msisdn}"
    }
    result=get("",qparams) do |request,response|
        raise_exception_on_error(response)
    end
    return result["api"]["request"]["mnp"]
  end
end
