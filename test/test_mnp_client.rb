require 'minitest/autorun'
require 'mnp_client'
require 'uri'
require 'commons'

class Hash
  def with_indifferent_access
    return self
  end
end

class MnpClientTest < Minitest::Test
    
    def setup
      TestSuiteConfig.load
    end    

    def mnp_response
      {
      api: {
          request: {
           common: {
           charged: 0, 
           reqid: 93, 
           status: "accepted"
           }, 
           mnp: {
           "name" => "TariffPL06", 
           "target" =>  "48514153254"
           }
         }
        }
      }      
    end

    def msisdn
      "48123123123"
    end

    def test_timeout
      Net::HTTP.trigger_timeout=true
      assert_raises(Net::ReadTimeout) {
        MnpClient.query(msisdn)
      }
      assert_equal "/uri?resformat=json&output=json&show_imsi=true&target=48123123123&appkey=appkey", Net::HTTP.last_request_path
    end

    def test_internal_error
      Net::HTTP.respond_internal_error
      assert_raises(GenericAPIClient::HTTPResponseException) {
        MnpClient.query(msisdn)
      }
      assert_equal "/uri?resformat=json&output=json&show_imsi=true&target=48123123123&appkey=appkey", Net::HTTP.last_request_path
    end

    def test_success
      Net::HTTP.respond_ok mnp_response.to_json
      assert_equal mnp_response[:api][:request][:mnp],MnpClient.query(msisdn)
      assert_equal "/uri?resformat=json&output=json&show_imsi=true&target=48123123123&appkey=appkey", Net::HTTP.last_request_path
    end

end
