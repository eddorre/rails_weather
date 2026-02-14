class ForecastsController < ApplicationController
  def show
    postcode = params[:postcode]
    cached_hash = Rails.cache.read(cache_key(postcode: postcode))

    unless cached_hash
      redirect_to new_forecast_path, alert: "Enter an address to get a forecast."
      return
    end

    @forecast = ForecastResult.from_h(cached_hash)
    @cached = true
  end

  def create
    @address = params[:address]
    response = WeatherForecaster.call(address: params[:address])
    forecast = response[:forecast_result]

    redirect_to forecast_path(forecast.postcode)
  rescue WeatherForecaster::GeocodingError, WeatherForecaster::WeatherServiceError => e
    flash.now[:alert] = e.message

    render :new, status: :unprocessable_content
  end

  private

  def cache_key(postcode:)
    "forecaster::v1::postcode:#{postcode}"
  end
end
