require 'generic_api_client'

class VcmpPaymentsClient < GenericAPIClient

  def self.reserved?(p)
  end

  class VcmpPayment < OpenStruct
  end

  def self.single_product_params(params)
  %Q(
          {"msisdn":"#{params[:msisdn]}",
          "buyChannel":"#{params[:buyChannel]}",
          "product":{
             "id":#{params[:product_id]},
             "name":"#{params[:title]}",
             "type":"#{params[:product_type]}"
          },
          "provider":{
             "id":#{params[:provider_id]},
             "name":"#{params[:provider_name]}"
          },
          "billingVolume":{
             "value":"#{params[:netpln]}"
          }
          }    
      )   
  end

  def self.custom_params(params)  
    %Q(
            {"msisdn":"#{params[:msisdn]}",
              "buyChannel":"#{params[:buyChannel]}",
              "product":{
                 "name":"#{params[:name]}",
                 "type":"#{params[:type]}",
                 "buyOptionCode": "#{params[:buyOptionCode]}",
                 "description": "#{params[:description]}"                 
              },
              "billingVolume":{
                 "value":"#{params[:netpln]}"
              }
            }    
        )   
  end

  def self.reserve(p)
    params=p.with_indifferent_access
    params.reject! {|k,v| v.nil?}    
    params=config.merge params
    tx_type=config[:apitype].gsub("-","_")
    body = method("#{tx_type}_params").call params
    
    begin    
      result=post("/#{config[:apitype]}",body) do |request,response|
        raise_exception_on_error(response)
      end         
    rescue HTTPResponseException => e
      case e.response
        when Net::HTTPPaymentRequired
          error_code = "VcmpPaymentsClient::InsufficientFunds"
        else
          error_code = e
      end
      Rails.logger.warn("VcmpPaymentsClient.reserve exception #{e} at #{e.backtrace[0..3]}")
      return VcmpPayment.new(
        :error?       => true,
        :code        =>  "#{error_code}",
      )
    rescue StandardError => e
      Rails.logger.warn("VcmpPaymentsClient.reserve exception #{e} at #{e.backtrace[0..3]}")
      return VcmpPayment.new(
        :error?       => true,
        :code        =>  "#{e}",
      )
    end          
    Rails.logger.debug("VcmpPaymentsClient.reserve(#{params.inspect}) returned #{result.inspect}")
    return VcmpPayment.new(
        :error?       => false,
        :charge_id    =>  result["id"],
        :billingVolume => result["billingVolume"]
      )
  end
  
  def self.charge(p)
    params=p.with_indifferent_access
    body = %Q(
      { 
        "billingVolume"=>{"value"=>"#{params[:netpln]}"}
      }
    )
    begin    
      result=post("/#{config[:apitype]}/#{params[:charge_id]}/debit",body) do |request,response|
        raise_exception_on_error(response)
      end         
    rescue HTTPResponseException => e
      Rails.logger.warn("VcmpPaymentsClient.charge exception #{e} at #{e.backtrace[0..3]}")
      return VcmpPayment.new(
        :error?       => true,
        :code        =>  "#{e}",
      )
    rescue StandardError => e
      Rails.logger.warn("VcmpPaymentsClient.charge exception #{e} at #{e.backtrace[0..3]}")
      return VcmpPayment.new(
        :error?       => true,
        :code        =>  "#{e}",
      )
    end          
    Rails.logger.debug("VcmpPaymentsClient.charge(#{params.inspect}) returned #{result.inspect}")
    return VcmpPayment.new(
        :error?       => false,
        :charge_id    =>  result["id"],
        :billingVolume => result["billingVolume"]
      ) 
  end

  def self.cancel(p)
    params=p.with_indifferent_access
    begin    
      result=delete("/#{config[:apitype]}/#{params[:charge_id]}") do |request,response|
        raise_exception_on_error(response)
      end         
    rescue HTTPResponseException => e
      Rails.logger.warn("VcmpPaymentsClient.cancel exception #{e} at #{e.backtrace[0..3]}")
      return VcmpPayment.new(
        :error?       => true,
        :code        =>  "#{e}",
      )
    rescue StandardError => e
      Rails.logger.warn("VcmpPaymentsClient.cancel exception #{e} at #{e.backtrace[0..3]}")
      return VcmpPayment.new(
        :error?       => true,
        :code        =>  "#{e}",
      )
    end          
    Rails.logger.debug("VcmpPaymentsClient.cancel(#{params.inspect}) returned #{result.inspect}")
    return VcmpPayment.new(
        :error?       => false
      )   
  end
  
end
