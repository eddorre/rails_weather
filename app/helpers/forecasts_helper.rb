module ForecastsHelper
  # Based on WMO Weather Interpretation Codes
  # from https://open-meteo.com/en/docs
  WEATHER_LABELS = {
    0 => "Clear sky",
    1 => "Mainly clear",
    2 => "Partly cloudy",
    3 => "Overcast",
    45 => "Fog",
    48 => "Fog",
    51 => "Light drizzle",
    53 => "Moderate drizzle",
    55 => "Dense drizzle",
    61 => "Light rain",
    63 => "Moderate rain",
    65 => "Heavy rain",
    71 => "Light snow",
    73 => "Moderate snow",
    75 => "Heavy snow",
    80 => "Rain showers",
    95 => "Thunderstorm"
  }.freeze

  def weather_label(code)
    WEATHER_LABELS[code] || "Unknown"
  end

    def weather_icon_key(code)
    case code
    when 0
      "clear-day"
    when 1, 2
      "partly-cloudy-day"
    when 3
      "cloudy"
    when 45, 48
      "fog"
    when 51..67, 80..82
      "rain"
    when 71..77
      "snow"
    when 95..99
      "thunderstorms"
    else
      "cloudy"
    end
  end
end
