require "rails_helper"

describe WeatherForecaster do
  describe ".call" do
    subject { described_class.call(address: "Seahawks Stadium", geocoder: geocoder, weather_service: weather_service, cache: cache) }

    let(:geocoder) { class_double(Integrations::Geocoders::Nominatim) }
    let(:weather_service) { class_double(Integrations::WeatherServices::OpenMeteo) }
    let(:cache) { instance_double(ActiveSupport::Cache::MemoryStore) }

    let(:geocode_result) { { latitude: "47.5953459", longitude: "-122.3316443", postcode: "98134" } }
    let(:weather_result) do
      {
        temperature_unit: "°F",
        current_temperature: 55.4,
        current_code: 3,
        days: [
          { date: "2024-01-15", min: 45.2, max: 58.3, code: 3 },
          { date: "2024-01-16", min: 42.8, max: 55.9, code: 61 }
        ]
      }
    end

    context "with a valid address" do
      before do
        allow(geocoder).to receive(:call).with(address: "Seahawks Stadium").and_return(geocode_result)
        allow(weather_service).to receive(:call).with(latitude: "47.5953459", longitude: "-122.3316443").and_return(weather_result)
      end

      context "when the forecast is not cached" do
        before do
          allow(cache).to receive(:read).with("forecaster::v1::postcode:98134").and_return(nil)
          allow(cache).to receive(:write)
        end

        it "returns the forecast result with cached: false" do
          result = subject

          expect(result[:cached]).to eq(false)
          expect(result[:forecast_result]).to be_a(ForecastResult)
          expect(result[:forecast_result].postcode).to eq("98134")
          expect(result[:forecast_result].current_temperature).to eq(55.4)
        end

        it "writes the forecast to the cache" do
          subject

          expect(cache).to have_received(:write).with(
            "forecaster::v1::postcode:98134",
            hash_including(postcode: "98134"),
            { expires_in: 30.minutes }
          )
        end
      end

      context "when the forecast is cached" do
        let(:cached_hash) do
          {
            postcode: "98134",
            temperature_unit: "°F",
            current_temperature: 50.0,
            current_code: 0,
            days: [
              { date: "2024-01-14", min: 40.0, max: 52.0, code: 0 }
            ]
          }
        end

        before do
          allow(cache).to receive(:read).with("forecaster::v1::postcode:98134").and_return(cached_hash)
        end

        it "returns the cached forecast result with cached: true" do
          result = subject

          expect(result[:cached]).to eq(true)
          expect(result[:forecast_result]).to be_a(ForecastResult)
          expect(result[:forecast_result].current_temperature).to eq(50.0)
        end

        it "does not call the weather service" do
          subject

          expect(weather_service).not_to have_received(:call)
        end
      end
    end

    context "when the geocoder raises an ApiError" do
      before do
        allow(geocoder).to receive(:call).and_raise(
          Integrations::Geocoders::Nominatim::ApiError, "Nominatim API request failed"
        )
      end

      it "raises a GeocodingError" do
        expect { subject }.to raise_error(
          WeatherForecaster::GeocodingError, "Nominatim API request failed"
        )
      end
    end

    context "when the geocoder raises a ResponseError" do
      before do
        allow(geocoder).to receive(:call).and_raise(
          Integrations::Geocoders::Nominatim::ResponseError, "Nominatim API response missing required fields"
        )
      end

      it "raises a GeocodingError" do
        expect { subject }.to raise_error(
          WeatherForecaster::GeocodingError, "Nominatim API response missing required fields"
        )
      end
    end

    context "when the weather service raises an ApiError" do
      before do
        allow(geocoder).to receive(:call).with(address: "Seahawks Stadium").and_return(geocode_result)
        allow(cache).to receive(:read).and_return(nil)
        allow(weather_service).to receive(:call).and_raise(
          Integrations::WeatherServices::OpenMeteo::ApiError, "Open-Meteo API request failed"
        )
      end

      it "raises a WeatherServiceError" do
        expect { subject }.to raise_error(
          WeatherForecaster::WeatherServiceError, "Open-Meteo API request failed"
        )
      end
    end

    context "when the weather service raises a ResponseError" do
      before do
        allow(geocoder).to receive(:call).with(address: "Seahawks Stadium").and_return(geocode_result)
        allow(cache).to receive(:read).and_return(nil)
        allow(weather_service).to receive(:call).and_raise(
          Integrations::WeatherServices::OpenMeteo::ResponseError, "Missing current section"
        )
      end

      it "raises a WeatherServiceError" do
        expect { subject }.to raise_error(
          WeatherForecaster::WeatherServiceError, "Missing current section"
        )
      end
    end
  end
end
