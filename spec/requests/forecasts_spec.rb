require "rails_helper"

RSpec.describe "Forecasts", type: :request do
  describe "GET /forecasts/new" do
    it "renders the new forecast form" do
      get new_forecast_path

      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /forecasts" do
    context "with a valid address" do
      let(:forecast_result) do
        ForecastResult.new(
          postcode: "98134",
          temperature_unit: "°F",
          current_temperature: 55.4,
          current_code: 3,
          days: [
            ForecastDay.new(date: "2024-01-15", min: 45.2, max: 58.3, code: 3)
          ]
        )
      end

      before do
        allow(WeatherForecaster).to receive(:call)
          .with(address: "Seahawks Stadium")
          .and_return({ forecast_result: forecast_result, cached: false })
      end

      it "redirects to the forecast show page" do
        post forecasts_path, params: { address: "Seahawks Stadium" }

        expect(response).to redirect_to(forecast_path("98134"))
      end
    end

    context "when the geocoder fails" do
      before do
        allow(WeatherForecaster).to receive(:call)
          .and_raise(WeatherForecaster::GeocodingError, "Nominatim API request failed")
      end

      it "renders the new template with an error" do
        post forecasts_path, params: { address: "invalid address" }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end

    context "when the weather service fails" do
      before do
        allow(WeatherForecaster).to receive(:call)
          .and_raise(WeatherForecaster::WeatherServiceError, "Open-Meteo API request failed")
      end

      it "renders the new template with an error" do
        post forecasts_path, params: { address: "Seahawks Stadium" }

        expect(response).to have_http_status(:unprocessable_content)
      end
    end
  end

  describe "GET /forecasts/:postcode" do
    context "when the forecast is cached" do
      let(:cached_hash) do
        {
          postcode: "98134",
          temperature_unit: "°F",
          current_temperature: 55.4,
          current_code: 3,
          days: [
            { date: "2024-01-15", min: 45.2, max: 58.3, code: 3 }
          ]
        }
      end

      before do
        allow(Rails.cache).to receive(:read)
          .with("forecaster::v1::postcode:98134")
          .and_return(cached_hash)
      end

      it "renders the forecast" do
        get forecast_path("98134")

        expect(response).to have_http_status(:ok)
      end
    end

    context "when the forecast is not cached" do
      before do
        allow(Rails.cache).to receive(:read)
          .with("forecaster::v1::postcode:00000")
          .and_return(nil)
      end

      it "redirects to the new forecast page" do
        get forecast_path("00000")

        expect(response).to redirect_to(new_forecast_path)
      end

      it "redirects to the new forecast page with an alert" do
        get forecast_path("00000")

        expect(flash[:alert]).to eq("Enter an address to get a forecast.")
      end
    end
  end
end
