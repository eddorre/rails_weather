module Integrations
  module Geocoders
    class Nominatim
      class ApiError < StandardError; end
      class ResponseError < StandardError; end

      BASE_URI = "https://nominatim.openstreetmap.org/search"

      attr_reader :address

      def self.call(address:)
        new(address:).call
      end

      def initialize(address:)
        @address = address
      end

      def call
        response = HTTP
          .timeout(connect: 3, read: 5)
          .headers("Accept" => "application/json")
          .get(BASE_URI, params: { q: address, format: "jsonv2", addressdetails: 1, limit: 1 })

        unless response.status.success?
          raise ApiError, "Nominatim API request failed"
        end

        parse_response(response)
      end

      private

      def parse_response(response)
        json = JSON.parse(response.body.to_s)&.first

        raise ResponseError, "Invalid response from Nominatim API" unless json

        postcode = json.dig("address", "postcode")
        latitude = json.dig("lat")
        longitude = json.dig("lon")

        attributes = [postcode, latitude, longitude].reject(&:blank?)

        raise ResponseError,
          "Nominatim API response missing required fields" if attributes.size < 3

        {
          latitude: json.dig("lat"),
          longitude: json.dig("lon"),
          postcode: json.dig("address", "postcode"),
        }
      rescue JSON::ParserError => e
        raise ResponseError, "Failed to parse Nominatim API response"
      end
    end
  end
end
