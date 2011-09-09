require 'httparty'

module Ebay
  class Finding
    SERVICE_VERSION="1.0.0"
    
    include HTTParty
    base_uri "svcs.ebay.com/services/search/FindingService/v1?SERVICE-VERSION=#{SERVICE_VERSION}&SECURITY-APPNAME=#{Ebay::Api.app_id}&RESPONSE-DATA-FORMAT=JSON&REST-PAYLOAD"
    format :json

    def self.find_by_keyword(keywords,page_number)
      parse_response(get("&OPERATION-NAME=findItemsByKeywords&paginationInput.pageNumber=#{page_number}",:query=>{:keywords=>keywords}))
    end
    
    def self.find_by_category(category,page_number)
      parse_response(get("&OPERATION-NAME=findItemsByCategory&paginationInput.pageNumber=#{page_number}",:query=>{:categoryId=>category}))
    end
    
    def self.parse_response(response)
      response=response.parsed_response["findItemsByCategoryResponse"][0]
      ack=response["ack"][0].downcase.to_sym
      message=response["errorMessage"][0]["error"][0]["message"][0] if ack==:failure
      if ack==:success
        items=response["searchResult"][0]["item"] 
        total_pages=Integer(response["paginationOutput"][0]["totalPages"].first)
        page_number=Integer(response["paginationOutput"][0]["pageNumber"].first)
      end
      {:ack=>ack,:message=>message,:items=>items,:total_pages=>total_pages,:page_number=>page_number}
    end
  end
end
