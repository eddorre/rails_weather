module Integrations
  module WeatherServices
    class OpenMeteo
      class ApiError < StandardError; end
      class ResponseError < StandardError; end

      BASE_URI = "https://api.open-meteo.com/v1/forecast"

      attr_reader :latitude, :longitude

      def self.call(latitude:, longitude:)
        new(latitude: latitude, longitude: longitude).call
      end

      def initialize(latitude:, longitude:)
        @latitude = latitude
        @longitude = longitude
      end

      def call
        response = HTTP
          .timeout(connect: 3, read: 5)
          .headers("Accept" => "application/json")
          .get(
            BASE_URI, params: {
              latitude:,
              longitude:,
              temperature_unit: "fahrenheit",
              current: "temperature_2m,weather_code",
              daily: "temperature_2m_max,temperature_2m_min,weather_code",
              forecast_days: 7,
              timezone: "auto"
            }
          )

        unless response.status.success?
          raise ApiError, "Open-Meteo API request failed"
        end

        parse_response(response)
      end

      private

      def parse_response(response)
        json = JSON.parse(response.body.to_s)

        raise ResponseError, "Invalid response from Open-Meteo API" unless json

        validate_json!(json)

        normalize_json(json)
      rescue JSON::ParserError
        raise ResponseError, "Failed to parse Open-Meteo API response"
      end

      def validate_json!(json)
        raise ResponseError, "Missing current section" unless json.dig("current")
        raise ResponseError, "Missing daily section" unless json.dig("daily")

        daily = json.dig("daily")

        %w[time temperature_2m_min temperature_2m_max weather_code].each do |key|
          raise ResponseError, "Missing daily value #{key}" unless daily.dig(key)
        end

        lengths = [
          daily.dig("time").size,
          daily.dig("temperature_2m_min").size,
          daily.dig("temperature_2m_max").size,
          daily.dig("weather_code").size
        ].uniq

        raise ResponseError, "Daily arrays have mismatched lengths" unless lengths.size == 1
      end

      def normalize_json(json)
        {
          temperature_unit: json.dig("current_units", "temperature_2m"),
          current_temperature: json.dig("current", "temperature_2m"),
          current_code: json.dig("current", "weather_code"),
          days: json.dig("daily", "time").map.with_index do |date, index|
            {
              date: date,
              min: json.dig("daily", "temperature_2m_min", index),
              max: json.dig("daily", "temperature_2m_max", index),
              code: json.dig("daily", "weather_code", index)
            }
          end
        }
      end
    end
  end
end
