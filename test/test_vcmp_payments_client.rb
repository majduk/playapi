require 'minitest/autorun'
require 'vcmp_payments_client'
require 'uri'
require 'commons'

class VcmpPaymentsClientTest < Minitest::Test
    def setup
      TestSuiteConfig.load
    end    

    def reserve_params
      {
        :msisdn => "123456789",
        :name => "product_name",
        :netpln => 1.23
      }
    end

    def test_timeout
      Net::HTTP.trigger_timeout=true
      assert_equal VcmpPaymentsClient::VcmpPayment.new(
        :error?       => true,
        :code        =>  "Net::ReadTimeout"
      ), VcmpPaymentsClient.reserve(reserve_params)
      assert_equal "/uri/custom?resformat=json&appkey=appkey", Net::HTTP.last_request_path
    end

    def test_success
      resp =  { 
        :id => "1234", 
        :billingVolume => "1.23PLN" 
      }
      Net::HTTP.respond_ok resp.to_json
      assert_equal VcmpPaymentsClient::VcmpPayment.new(
        :error?       => false,
        :charge_id => "1234", 
        :billingVolume => "1.23PLN"
      ), VcmpPaymentsClient.reserve(reserve_params)
      assert_equal "/uri/custom?resformat=json&appkey=appkey", Net::HTTP.last_request_path
    end

    def test_bad_request
      Net::HTTP.respond_bad_request
      assert_equal VcmpPaymentsClient::VcmpPayment.new(
        :error?       => true,
        :code        =>  "VcmpPaymentsClient::Net::HTTPBadRequest"
      ), VcmpPaymentsClient.reserve(reserve_params)
      assert_equal "/uri/custom?resformat=json&appkey=appkey", Net::HTTP.last_request_path
    end

    def test_payment_required
      Net::HTTP.respond_payment_required
      assert_equal VcmpPaymentsClient::VcmpPayment.new(
        :error?       => true,
        :code        =>  "VcmpPaymentsClient::InsufficientFunds"
      ), VcmpPaymentsClient.reserve(reserve_params)
      assert_equal "/uri/custom?resformat=json&appkey=appkey", Net::HTTP.last_request_path
    end


end
