require "rails_helper"

describe ForecastResult do
  let(:days) do
    [
      ForecastDay.new(date: "2024-01-15", min: 45.2, max: 58.3, code: 3),
      ForecastDay.new(date: "2024-01-16", min: 42.8, max: 55.9, code: 61)
    ]
  end

  let(:forecast_result) do
    described_class.new(
      postcode: "98134",
      temperature_unit: "°F",
      current_temperature: 55.4,
      current_code: 3,
      days: days
    )
  end

  describe "#to_h" do
    let(:result) { forecast_result.to_h }

    it "includes the postcode" do
      expect(result[:postcode]).to eq("98134")
    end

    it "includes the temperature_unit" do
      expect(result[:temperature_unit]).to eq("°F")
    end

    it "includes the current_temperature" do
      expect(result[:current_temperature]).to eq(55.4)
    end

    it "includes the current_code" do
      expect(result[:current_code]).to eq(3)
    end

    it "converts days to hashes" do
      expect(result[:days]).to all(be_a(Hash))
    end

    it "includes the correct number of days" do
      expect(result[:days].size).to eq(2)
    end
  end

  describe ".from_h" do
    let(:hash) do
      {
        postcode: "98134",
        temperature_unit: "°F",
        current_temperature: 55.4,
        current_code: 3,
        days: [
          { date: "2024-01-15", min: 45.2, max: 58.3, code: 3 },
          { date: "2024-01-16", min: 42.8, max: 55.9, code: 61 }
        ]
      }
    end

    let(:result) { described_class.from_h(hash) }

    it "returns a ForecastResult" do
      expect(result).to be_a(ForecastResult)
    end

    it "sets the postcode" do
      expect(result.postcode).to eq("98134")
    end

    it "sets the temperature_unit" do
      expect(result.temperature_unit).to eq("°F")
    end

    it "sets the current_temperature" do
      expect(result.current_temperature).to eq(55.4)
    end

    it "sets the current_code" do
      expect(result.current_code).to eq(3)
    end

    it "converts days to ForecastDay objects" do
      expect(result.days).to all(be_a(ForecastDay))
    end

    it "sets the correct number of days" do
      expect(result.days.size).to eq(2)
    end

    context "with string keys" do
      let(:hash) do
        {
          "postcode" => "98134",
          "temperature_unit" => "°F",
          "current_temperature" => 55.4,
          "current_code" => 3,
          "days" => [
            { "date" => "2024-01-15", "min" => 45.2, "max" => 58.3, "code" => 3 }
          ]
        }
      end

      it "symbolizes the keys" do
        expect(result.postcode).to eq("98134")
      end

      it "symbolizes nested day keys" do
        expect(result.days.first.date).to eq("2024-01-15")
      end
    end

    context "with missing keys" do
      let(:hash) { { postcode: "98134" } }

      it "raises a KeyError" do
        expect { result }.to raise_error(KeyError)
      end
    end
  end
end
