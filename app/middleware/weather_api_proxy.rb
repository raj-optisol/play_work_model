require 'torquebox-cache'

class WeatherApiProxy
  def initialize(app, &block)
    self.class.send(:define_method, :uri_for, &block)
    @app = app
  end

  def call(env)
    req = Rack::Request.new(env)
    city = req["q"]

    if city.nil? || city.empty?
      @app.call(env)
    end

    cache = TorqueBox::Infinispan::Cache.new( :name => 'weather' )

    if ( cached_val = cache.get(city.downcase))
      headers = {
        "Content-Type" => "application/json, charset=utf-8",
        "Content-Length" => cached_val.length.to_s
      }
      return [200, headers, [cached_val]]
    end

    method = req.request_method.downcase
    method[0..0] = method[0..0].upcase

    return @app.call(env) unless uri = uri_for(req)

    sub_request = Net::HTTP.const_get(method).new("#{uri.path}#{"?" if uri.query}#{uri.query}")

    if sub_request.request_body_permitted? and req.body
      sub_request.body_stream = req.body
      sub_request.content_length = req.content_length
      sub_request.content_type = req.content_type
    end

    sub_request["X-Forwarded-For"] = (req.env["X-Forwarded-For"].to_s.split(/, +/) + [req.env['REMOTE_ADDR']]).join(", ")
    sub_request["Accept-Encoding"] = req.accept_encoding
    sub_request["Referer"] = req.referer

    sub_response = Net::HTTP.start(uri.host, uri.port) do |http|
      http.request(sub_request)
    end

    headers = {}
    sub_response.each_header do |k,v|
      headers[k] = v unless k.to_s =~ /cookie|content-length|transfer-encoding/i
    end

    cache.put(city.downcase, sub_response.read_body, expires=24*3600)
    [sub_response.code.to_i, headers, [sub_response.read_body]]
  end
end
