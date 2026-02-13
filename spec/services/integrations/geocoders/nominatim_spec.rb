require "rails_helper"

describe Integrations::Geocoders::Nominatim do
  describe ".call" do
    subject { described_class.call(address: "Seahawks Stadium") }

    context "with a valid address" do
      let(:response) do
        [
          {
            "address" =>
            {
              "postcode" => "98134",
            },
            "lat" => "47.5953459",
            "lon" => "-122.3316443"
          }
        ]
      end
      let(:result) { { latitude: "47.5953459", longitude: "-122.3316443", postcode: "98134" } }

      before do
        allow(HTTP).to receive_message_chain(:timeout, :headers, :get)
          .and_return(double(status: double(success?: true), body: response.to_json))
      end

      it "returns the correct latitude, longitude, and postcode" do
        expect(subject).to eq(result)
      end

      context 'when the API returns an error' do
        before do
          allow(HTTP).to receive_message_chain(:timeout, :headers, :get)
            .and_return(double(status: double(success?: false)))
        end

        it "raises an ApiError" do
          expect { subject }.to raise_error(
            Integrations::Geocoders::Nominatim::ApiError, "Nominatim API request failed"
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
            Integrations::Geocoders::Nominatim::ResponseError,
            "Failed to parse Nominatim API response"
          )
        end
      end

      context "when the API returns a response with missing required fields" do
        before do
          allow(HTTP).to receive_message_chain(:timeout, :headers, :get)
            .and_return(double(status: double(success?: true), body: response.to_json))
        end

        context "when the address is empty" do
          let(:response) do
            [
              {
                "address" => {},
                "lat" => "47.5953459",
                "lon" => "-122.3316443"
              }
            ]
          end

          it "raises a ResponseError" do
            expect { subject }.to raise_error(
              Integrations::Geocoders::Nominatim::ResponseError,
              "Nominatim API response missing required fields"
            )
          end
        end

        context "when the postcode is empty" do
          let(:response) do
            [
              {
                "address" => { "postcode" => "" },
                "lat" => "47.5953459",
                "lon" => "-122.3316443"
              }
            ]
          end

          it "raises a ResponseError" do
            expect { subject }.to raise_error(Integrations::Geocoders::Nominatim::ResponseError)
          end
        end

        context "when the lat is missing" do
          let(:response) do
            [
              {
                "address" =>
                {
                  "postcode" => "98134",
                },
                "lon" => "-122.3316443"
              }
            ]
          end

          it "raises a ResponseError" do
            expect { subject }.to raise_error(Integrations::Geocoders::Nominatim::ResponseError)
          end
        end

        context "when the lon is missing" do
          let(:response) do
            [
              {
                "address" =>
                {
                  "postcode" => "98134",
                },
                "lat" => "47.5953459"
              }
            ]
          end

          it "raises a ResponseError" do
            expect { subject }.to raise_error(Integrations::Geocoders::Nominatim::ResponseError)
          end
        end

        context "when the lat is empty" do
          let(:response) do
            [
              {
                "address" => { "postcode" => "" },
                "lat" => "",
                "lon" => "-122.3316443"
              }
            ]
          end

          it "raises a ResponseError" do
            expect { subject }.to raise_error(Integrations::Geocoders::Nominatim::ResponseError)
          end
        end

        context "when the lon is empty" do
          let(:response) do
            [
              {
                "address" => { "postcode" => "" },
                "lat" => "47.5953459",
                "lon" => ""
              }
            ]
          end

          it "raises a ResponseError" do
            expect { subject }.to raise_error(Integrations::Geocoders::Nominatim::ResponseError)
          end
        end
      end

      context 'when the API returns an empty array' do
        before do
          allow(HTTP).to receive_message_chain(:timeout, :headers, :get)
            .and_return(double(status: double(success?: true), body: "[]"))
        end

        it "raises a ResponseError" do
          expect { subject }.to raise_error(Integrations::Geocoders::Nominatim::ResponseError)
        end
      end
    end

    context "with an invalid address" do
      subject { described_class.call(address: "invalid address") }
      let(:response) { "[]" }

      before do
        allow(HTTP).to receive_message_chain(:timeout, :headers, :get)
          .and_return(double(status: double(success?: true), body: response))
      end

      it "raises a ResponseError" do
        expect { subject }.to raise_error(Integrations::Geocoders::Nominatim::ResponseError)
      end
    end
  end
end
