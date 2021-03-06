require 'httparty'

module Ebay
  class Finding
    SERVICE_VERSION="1.0.0"
    
    include HTTParty
    base_uri "svcs.ebay.com/services/search/FindingService/v1?SERVICE-VERSION=#{SERVICE_VERSION}&RESPONSE-DATA-FORMAT=JSON&REST-PAYLOAD"
    format :json

    def self.find_by_keyword(params)
      params.merge!({:call_name=>"findItemsByKeywords"})
      parse_response(get(Finding.build_call(params),:query=>{:keywords=>params[:keywords]}))
    end
    
    def self.find_by_category(params)
      params.merge!({:call_name=>"findItemsByCategory"})
      parse_response(get(Finding.build_call(params),:query=>{:categoryId=>params[:category]}))
    end
    
    def self.parse_response(response)
      if !response.parsed_response.has_key?("findItemsByCategoryResponse")
        return {:ack=>:failure,:message=>response["errorMessage"][0]["error"][0]["message"][0],:items=>nil,:total_pages=>nil,:page_number=>nil}
      end
      
      response=response.parsed_response["findItemsByCategoryResponse"][0]
      ack=response["ack"][0].downcase.to_sym
      message=response["errorMessage"][0]["error"][0]["message"][0] if ack==:failure
      if ack==:success
        items=response["searchResult"][0]["item"] 
        total_pages=Integer(response["paginationOutput"][0]["totalPages"].first)
        page_number=Integer(response["paginationOutput"][0]["pageNumber"].first)
      end
      Finding.clean_hash({:ack=>ack,:message=>message,:items=>items,:total_pages=>total_pages,:page_number=>page_number},["items"])
    end
    
    def self.build_call(params)
      call_params="&SECURITY-APPNAME=#{Ebay::Api.app_id}&GLOBAL-ID=#{params[:global_id]}&OPERATION-NAME=#{params[:call_name]}&paginationInput.pageNumber=#{params[:page_number]}&itemFilter(0).name=ListingType&itemFilter(0).value(0)=#{params[:listing_type]}"
      call_params=call_params+"&buyerPostalCode=75001&itemFilter.name=MaxDistance&itemFilter.value=8000" if params[:listing_type]=="Classified" 
      call_params
    end
    
    def self.clean_hash(h,exceptions)
    	h.each_key do |k|
    		if h[k].is_a?(Array) && h[k].first.is_a?(Hash) 
    		  h[k].each_index {|index|Finding.clean_hash(h[k][index],exceptions)}
    		end
    		if h[k].is_a?(Array) && h[k].count==1 && !exceptions.include?(k.to_s)
    		  h[k]=h[k].first 
    		end
    	end
    end
  end
end
