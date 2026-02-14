class WeatherForecaster
  class GeocodingError < StandardError; end
  class WeatherServiceError < StandardError; end

  attr_reader :address, :geocoder, :weather_service, :cache

  def self.call(address:, geocoder: nil, weather_service: nil, cache: nil)
    new(address: address, geocoder: geocoder, weather_service: weather_service, cache: cache).call
  end

  def initialize(address:, geocoder: nil, weather_service: nil, cache: nil)
    @address = address
    @geocoder = geocoder || Integrations::Geocoders::Nominatim
    @weather_service = weather_service || Integrations::WeatherServices::OpenMeteo
    @cache = cache || Rails.cache
  end

  def call
    geocode_result = geocoder.call(address: address)
    postcode = geocode_result[:postcode]

    if (cached_hash = cache.read(cache_key(postcode: postcode)))
      forecast_result = ForecastResult.from_h(cached_hash)
      return { forecast_result: forecast_result, cached: true }
    end

    weather_result = weather_service.call(
      latitude: geocode_result[:latitude], longitude: geocode_result[:longitude]
    )

    forecast_result = ForecastResult.from_h(weather_result.merge(postcode: postcode))

    cache.write(cache_key(postcode: postcode), forecast_result.to_h, expires_in: 30.minutes)

    { forecast_result: forecast_result, cached: false }

  rescue Integrations::Geocoders::Nominatim::ApiError, Integrations::Geocoders::Nominatim::ResponseError => e
    raise GeocodingError, e.message
  rescue Integrations::WeatherServices::OpenMeteo::ApiError, Integrations::WeatherServices::OpenMeteo::ResponseError => e
    raise WeatherServiceError, e.message
  end

  private

  def cache_key(postcode:)
    "forecaster::v1::postcode:#{postcode}"
  end
end
