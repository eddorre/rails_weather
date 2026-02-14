require "rails_helper"

RSpec.describe ForecastsHelper, type: :helper do
  describe "#weather_label" do
    context "with known weather codes" do
      it "returns 'Clear sky' for code 0" do
        expect(helper.weather_label(0)).to eq("Clear sky")
      end

      it "returns 'Mainly clear' for code 1" do
        expect(helper.weather_label(1)).to eq("Mainly clear")
      end

      it "returns 'Partly cloudy' for code 2" do
        expect(helper.weather_label(2)).to eq("Partly cloudy")
      end

      it "returns 'Overcast' for code 3" do
        expect(helper.weather_label(3)).to eq("Overcast")
      end

      it "returns 'Fog' for code 45" do
        expect(helper.weather_label(45)).to eq("Fog")
      end

      it "returns 'Light drizzle' for code 51" do
        expect(helper.weather_label(51)).to eq("Light drizzle")
      end

      it "returns 'Moderate rain' for code 63" do
        expect(helper.weather_label(63)).to eq("Moderate rain")
      end

      it "returns 'Heavy snow' for code 75" do
        expect(helper.weather_label(75)).to eq("Heavy snow")
      end

      it "returns 'Thunderstorm' for code 95" do
        expect(helper.weather_label(95)).to eq("Thunderstorm")
      end
    end

    context "with unknown weather codes" do
      it "returns 'Unknown' for unrecognized codes" do
        expect(helper.weather_label(999)).to eq("Unknown")
      end
    end
  end

  describe "#weather_icon_key" do
    context "with clear weather" do
      it "returns 'clear-day' for code 0" do
        expect(helper.weather_icon_key(0)).to eq("clear-day")
      end
    end

    context "with partly cloudy weather" do
      it "returns 'partly-cloudy-day' for code 1" do
        expect(helper.weather_icon_key(1)).to eq("partly-cloudy-day")
      end

      it "returns 'partly-cloudy-day' for code 2" do
        expect(helper.weather_icon_key(2)).to eq("partly-cloudy-day")
      end
    end

    context "with overcast weather" do
      it "returns 'cloudy' for code 3" do
        expect(helper.weather_icon_key(3)).to eq("cloudy")
      end
    end

    context "with fog" do
      it "returns 'fog' for code 45" do
        expect(helper.weather_icon_key(45)).to eq("fog")
      end

      it "returns 'fog' for code 48" do
        expect(helper.weather_icon_key(48)).to eq("fog")
      end
    end

    context "with rain" do
      it "returns 'rain' for code 51 (light drizzle)" do
        expect(helper.weather_icon_key(51)).to eq("rain")
      end

      it "returns 'rain' for code 63 (moderate rain)" do
        expect(helper.weather_icon_key(63)).to eq("rain")
      end

      it "returns 'rain' for code 80 (rain showers)" do
        expect(helper.weather_icon_key(80)).to eq("rain")
      end
    end

    context "with snow" do
      it "returns 'snow' for code 71 (light snow)" do
        expect(helper.weather_icon_key(71)).to eq("snow")
      end

      it "returns 'snow' for code 75 (heavy snow)" do
        expect(helper.weather_icon_key(75)).to eq("snow")
      end
    end

    context "with thunderstorm" do
      it "returns 'thunderstorms' for code 95" do
        expect(helper.weather_icon_key(95)).to eq("thunderstorms")
      end

      it "returns 'thunderstorms' for code 99" do
        expect(helper.weather_icon_key(99)).to eq("thunderstorms")
      end
    end

    context "with unknown codes" do
      it "returns 'cloudy' as the default" do
        expect(helper.weather_icon_key(999)).to eq("cloudy")
      end
    end
  end
end
