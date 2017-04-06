require 'minitest/autorun'
require 'ussd_auth_client'
require 'uri'
require 'commons'

class UssdAuthClientTest < Minitest::Test
    def setup
      TestSuiteConfig.load
    end    

    def auth_params()
      {
        :msisdn => "123456789",
        :challenge => "challenge_text",
        :expect => "input"
      }
    end

    def test_timeout
      Net::HTTP.trigger_timeout=true
      assert_raises(UssdAuthClient::Timeout) {
        UssdAuthClient.authenticate auth_params
      }
      assert_equal "/uri?resformat=json&appkey=appkey", Net::HTTP.last_request_path
    end

    def test_authenticated
      response={ :ussdSessionCreationParameters =>
                 {:outboundSessionMessageRequest =>{
                   :outboundUSSDTextMessage=>{
                     :response=>"input"
                   }
                 },
                 :ussdSessionInformation => {
                 :ussdSessionIdentifier=>"1234"
                 }
                 }
      }
      Net::HTTP.respond_ok response.to_json
      assert_equal true, UssdAuthClient.authenticate(auth_params)
      assert_equal "/uri/1234/terminate?resformat=json&appkey=appkey", Net::HTTP.last_request_path
    end 

    def test_not_authenticated
      response={ :ussdSessionCreationParameters =>
                 {:outboundSessionMessageRequest =>{
                   :outboundUSSDTextMessage=>{
                     :response=>"xxxx"
                   }
                 },
                 :ussdSessionInformation => {
                 :ussdSessionIdentifier=>"1234"
                 }
                 }
      }
      Net::HTTP.respond_ok response.to_json
      assert_equal false, UssdAuthClient.authenticate(auth_params)
      assert_equal "/uri/1234/terminate?resformat=json&appkey=appkey", Net::HTTP.last_request_path
    end 


    def test_internal_error_no_body
      Net::HTTP.respond_internal_error
      assert_raises(UssdAuthClient::Error) {
        UssdAuthClient.authenticate auth_params
      }
      assert_equal "/uri?resformat=json&appkey=appkey", Net::HTTP.last_request_path
    end

    def test_internal_error_submit_failed
      response={
      "requestError" => {
       "serviceException" => {
        "messageId" => "SVC0001",
         "text" => "A service error occurred. Error code is %",
         "variables" => [ "submit_sm or submit_multi failed" ]
        }
       }
      }
      Net::HTTP.respond_internal_error response.to_json
      assert_raises(UssdAuthClient::Error) {
        UssdAuthClient.authenticate auth_params
      }
      assert_equal "/uri?resformat=json&appkey=appkey", Net::HTTP.last_request_path
    end

    def test_internal_error_submit_timed_out
      response={
      "requestError" => {
       "serviceException" => {
        "messageId" => "SVC0001",
         "text" => "A service error occurred. Error code is %",
         "variables" => [ "submit_sm or submit_multi timed out" ]
        }
       }
      }
      Net::HTTP.respond_internal_error response.to_json
      assert_raises(UssdAuthClient::Timeout) {
        UssdAuthClient.authenticate auth_params
      }
      assert_equal "/uri?resformat=json&appkey=appkey", Net::HTTP.last_request_path
    end

    def test_internal_error_submit_aborted
      response={
      "requestError" => {
       "serviceException" => {
        "messageId" => "SVC0001",
         "text" => "A service error occurred. Error code is %",
         "variables" => [ "submit_sm or submit_multi aborted" ]
        }
       }
      }
      Net::HTTP.respond_internal_error response.to_json
      assert_raises(UssdAuthClient::Abort) {
        UssdAuthClient.authenticate auth_params
      }
      assert_equal "/uri?resformat=json&appkey=appkey", Net::HTTP.last_request_path
    end

    def test_internal_error_submit_absent
      response={
      "requestError" => {
       "serviceException" => {
        "messageId" => "SVC0001",
         "text" => "A service error occurred. Error code is %",
         "variables" => [ "Absent Subscriber" ]
        }
       }
      }
      Net::HTTP.respond_internal_error response.to_json
      assert_raises(UssdAuthClient::Absent) {
        UssdAuthClient.authenticate auth_params
      }
      assert_equal "/uri?resformat=json&appkey=appkey", Net::HTTP.last_request_path
    end


    def test_bad_request
      response={"param"=>"value"}
      Net::HTTP.respond_internal_error response.to_json
      assert_raises(UssdAuthClient::Error) {
        UssdAuthClient.authenticate auth_params
      }
      assert_equal "/uri?resformat=json&appkey=appkey", Net::HTTP.last_request_path
    end

end
