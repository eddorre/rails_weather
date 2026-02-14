ForecastResult = Data.define(:postcode, :temperature_unit, :current_temperature, :current_code, :days) do
  def to_h
    {
      postcode: postcode,
      temperature_unit: temperature_unit,
      current_temperature: current_temperature,
      current_code: current_code,
      days: days.map(&:to_h)
    }
  end

  def self.from_h(hash)
    symbolized_hash = hash.deep_symbolize_keys

    new(
      postcode: symbolized_hash.fetch(:postcode),
      temperature_unit: symbolized_hash.fetch(:temperature_unit),
      current_temperature: symbolized_hash.fetch(:current_temperature),
      current_code: symbolized_hash.fetch(:current_code),
      days: symbolized_hash.fetch(:days).map { |day| ForecastDay.new(**day) }
    )
  end
end
