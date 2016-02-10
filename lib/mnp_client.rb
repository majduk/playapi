require 'generic_api_client'

class MnpClient  < GenericAPIClient
  def self.query(msisdn)
    qparams={
      "output"=>"json",
      "show_imsi"=>"true",
      "target" => "#{msisdn}"
    }
    return get("",qparams) do |request,response|
        return_nil_on_error(response)
    end
  end
end
