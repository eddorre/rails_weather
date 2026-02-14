# Integration client for the Nominatim (OpenStreetMap) geocoding API.
#
# Responsible for translating a user-supplied address or location string
# into geographic coordinates (latitude and longitude) and a postcode.
#
# Only the minimal subset of response data required by the application
# is extracted and normalized. Full schema validation is intentionally
# avoided due to the small surface area of data being consumed.
#
# Raises ApiError if the request fails or the response cannot be parsed.
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

      # limit: 1 ensures we only consider the most relevant match.
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

      # Extracts the first result from the Nominatim response and
      # validates that required fields (postcode, lat, lon) are present.
      #
      # Nominatim returns an array of results; we assume the first
      # entry is the most relevant match.
      def parse_response(response)
        json = JSON.parse(response.body.to_s)&.first

        raise ResponseError, "Invalid response from Nominatim API" unless json

        postcode = json.dig("address", "postcode")
        latitude = json.dig("lat")
        longitude = json.dig("lon")

        # Ensure all required fields are present before returning normalized data.
        attributes = [postcode, latitude, longitude].reject(&:blank?)

        raise ResponseError,
          "Nominatim API response missing required fields" if attributes.size < 3

        {
          postcode: postcode,
          latitude: latitude,
          longitude: longitude
        }
      rescue JSON::ParserError => e
        raise ResponseError, "Failed to parse Nominatim API response"
      end
    end
  end
end
