require "rails_helper"

describe Integrations::WeatherServices::OpenMeteo do
  describe ".call" do
    subject { described_class.call(latitude: "47.5953459", longitude: "-122.3316443") }

    context "with valid coordinates" do
      let(:response) do
        {
          "current_units" => {
            "temperature_2m" => "°F"
          },
          "current" => {
            "temperature_2m" => 55.4,
            "weather_code" => 3
          },
          "daily" => {
            "time" => ["2024-01-15", "2024-01-16", "2024-01-17"],
            "temperature_2m_min" => [45.2, 42.8, 48.1],
            "temperature_2m_max" => [58.3, 55.9, 62.4],
            "weather_code" => [3, 61, 0]
          }
        }
      end
      let(:result) do
        {
          temperature_unit: "°F",
          current_temperature: 55.4,
          current_code: 3,
          days: [
            { date: "2024-01-15", min: 45.2, max: 58.3, code: 3 },
            { date: "2024-01-16", min: 42.8, max: 55.9, code: 61 },
            { date: "2024-01-17", min: 48.1, max: 62.4, code: 0 }
          ]
        }
      end

      before do
        allow(HTTP).to receive_message_chain(:timeout, :headers, :get)
          .and_return(double(status: double(success?: true), body: response.to_json))
      end

      it "returns normalized weather data" do
        expect(subject).to eq(result)
      end

      context "when the API returns an error" do
        before do
          allow(HTTP).to receive_message_chain(:timeout, :headers, :get)
            .and_return(double(status: double(success?: false)))
        end

        it "raises an ApiError" do
          expect { subject }.to raise_error(
            Integrations::WeatherServices::OpenMeteo::ApiError, "Open-Meteo API request failed"
          )
        end
      end

      context "when the API returns invalid JSON" do
        before do
          allow(HTTP).to receive_message_chain(:timeout, :headers, :get)
            .and_return(double(status: double(success?: true), body: nil))
        end

        it "raises a ResponseError" do
          expect { subject }.to raise_error(
            Integrations::WeatherServices::OpenMeteo::ResponseError,
            "Failed to parse Open-Meteo API response"
          )
        end
      end

      context "when the API returns a response with missing required fields" do
        before do
          allow(HTTP).to receive_message_chain(:timeout, :headers, :get)
            .and_return(double(status: double(success?: true), body: response.to_json))
        end

        context "when the current section is missing" do
          let(:response) do
            {
              "daily" => {
                "time" => ["2024-01-15"],
                "temperature_2m_min" => [45.2],
                "temperature_2m_max" => [58.3],
                "weather_code" => [3]
              }
            }
          end

          it "raises a ResponseError" do
            expect { subject }.to raise_error(
              Integrations::WeatherServices::OpenMeteo::ResponseError,
              "Missing current section"
            )
          end
        end

        context "when the daily section is missing" do
          let(:response) do
            {
              "current" => {
                "temperature_2m" => 55.4,
                "weather_code" => 3
              }
            }
          end

          it "raises a ResponseError" do
            expect { subject }.to raise_error(
              Integrations::WeatherServices::OpenMeteo::ResponseError,
              "Missing daily section"
            )
          end
        end

        context "when the daily time is missing" do
          let(:response) do
            {
              "current" => {
                "temperature_2m" => 55.4,
                "weather_code" => 3
              },
              "daily" => {
                "temperature_2m_min" => [45.2],
                "temperature_2m_max" => [58.3],
                "weather_code" => [3]
              }
            }
          end

          it "raises a ResponseError" do
            expect { subject }.to raise_error(
              Integrations::WeatherServices::OpenMeteo::ResponseError,
              "Missing daily value time"
            )
          end
        end

        context "when the daily temperature_2m_min is missing" do
          let(:response) do
            {
              "current" => {
                "temperature_2m" => 55.4,
                "weather_code" => 3
              },
              "daily" => {
                "time" => ["2024-01-15"],
                "temperature_2m_max" => [58.3],
                "weather_code" => [3]
              }
            }
          end

          it "raises a ResponseError" do
            expect { subject }.to raise_error(
              Integrations::WeatherServices::OpenMeteo::ResponseError,
              "Missing daily value temperature_2m_min"
            )
          end
        end

        context "when the daily temperature_2m_max is missing" do
          let(:response) do
            {
              "current" => {
                "temperature_2m" => 55.4,
                "weather_code" => 3
              },
              "daily" => {
                "time" => ["2024-01-15"],
                "temperature_2m_min" => [45.2],
                "weather_code" => [3]
              }
            }
          end

          it "raises a ResponseError" do
            expect { subject }.to raise_error(
              Integrations::WeatherServices::OpenMeteo::ResponseError,
              "Missing daily value temperature_2m_max"
            )
          end
        end

        context "when the daily weather_code is missing" do
          let(:response) do
            {
              "current" => {
                "temperature_2m" => 55.4,
                "weather_code" => 3
              },
              "daily" => {
                "time" => ["2024-01-15"],
                "temperature_2m_min" => [45.2],
                "temperature_2m_max" => [58.3]
              }
            }
          end

          it "raises a ResponseError" do
            expect { subject }.to raise_error(
              Integrations::WeatherServices::OpenMeteo::ResponseError,
              "Missing daily value weather_code"
            )
          end
        end

        context "when the daily arrays have mismatched lengths" do
          let(:response) do
            {
              "current" => {
                "temperature_2m" => 55.4,
                "weather_code" => 3
              },
              "daily" => {
                "time" => ["2024-01-15", "2024-01-16"],
                "temperature_2m_min" => [45.2],
                "temperature_2m_max" => [58.3, 55.9],
                "weather_code" => [3, 61]
              }
            }
          end

          it "raises a ResponseError" do
            expect { subject }.to raise_error(
              Integrations::WeatherServices::OpenMeteo::ResponseError,
              "Daily arrays have mismatched lengths"
            )
          end
        end
      end
    end

    context "with invalid coordinates" do
      subject { described_class.call(latitude: "999", longitude: "999") }

      before do
        allow(HTTP).to receive_message_chain(:timeout, :headers, :get)
          .and_return(double(status: double(success?: false)))
      end

      it "raises an ApiError" do
        expect { subject }.to raise_error(
          Integrations::WeatherServices::OpenMeteo::ApiError, "Open-Meteo API request failed"
        )
      end
    end
  end
end
