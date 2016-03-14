
require ::File.expand_path('../config/environment',  __FILE__)

map '/weather_api' do
  use WeatherApiProxy do |req|
    city = req["q"]
    return if city.nil?
    url = "http://api.openweathermap.org/data/2.5/forecast/daily?mode=json&units=imperial&cnt=7&q="
    URI.parse(url + city)
  end
end

run KyckRegistrarWeb::Application
