module MessageRepository
  # extend Edr::AR::Repository
  # extend CommonFinders::ActiveRecord  
  # set_model_class Order

  # attrs = {guid:@obj.guid, limit:per_page, offset:offset}
  def self.get_messages attrs={}
    
    request = Faraday::Connection.new Settings.kyck.messaging.url , :ssl => {         
      :verify => false,
      :client_cert => OpenSSL::X509::Certificate.new(File.read(Settings.kyck.messaging.cert)),
      :client_key => OpenSSL::PKey::RSA.new(File.read(Settings.kyck.messaging.key)),      
    }

    request.headers['Accept'] = 'application/json'
    request.headers['Content-Type'] = 'application/json'    

    response = request.get "/messages", {:target => attrs}

    return response.body if response.status >= 200 && response.status <= 300
    return []

  end

  #attrs = {sender:{guid:sender.guid, name:sender.name}, recipients:[{guid:rec.guid, name:rec.name, email:rec.email, text:rec.text}], content:""}
  def self.create_message attrs={}
    request = Faraday::Connection.new Settings.kyck.messaging.url , :ssl => {         
      :verify => false,      
      :client_cert => OpenSSL::X509::Certificate.new(File.read(Settings.kyck.messaging.cert)),
      :client_key => OpenSSL::PKey::RSA.new(File.read(Settings.kyck.messaging.key)),      
      }

    #   Rails.logger.info(File.read("/usr/local/etc/nginx/ssl/social-client.crt").gsub(/\n/, "\t"));
    # request.headers['cert'] = File.read("/usr/local/etc/nginx/ssl/social-client.crt").gsub(/\n/, "\t")
    # request.headers['testtest'] = "blah blah"
    request.headers['Accept'] = 'application/json'
    request.headers['Content-Type'] = 'application/json'      
    response = request.post "/messages", {:message => attrs}.to_json
    Rails.logger.info "8*** CREATED MESSAGE using #{Settings.kyck.messaging.url}"
    return response.body if response.status >= 200 && response.status <= 300        
    {}
  end
  
  def self.delete_message attrs={}
    # request = Faraday::Connection.new Settings.kyck.messaging.url , :ssl => {         
    #   :verify => false,      
    #   :client_cert => OpenSSL::X509::Certificate.new(File.read(Settings.kyck.messaging.cert)),
    #   :client_key => OpenSSL::PKey::RSA.new(File.read(Settings.kyck.messaging.key)),      
    #   }
    # 
    # #   Rails.logger.info(File.read("/usr/local/etc/nginx/ssl/social-client.crt").gsub(/\n/, "\t"));
    # # request.headers['cert'] = File.read("/usr/local/etc/nginx/ssl/social-client.crt").gsub(/\n/, "\t")
    # # request.headers['testtest'] = "blah blah"
    # request.headers['Accept'] = 'application/json'
    # request.headers['Content-Type'] = 'application/json'      
    # response = request.post "/messages", {:message => attrs}.to_json
    # return response.body if response.status >= 200 && response.status <= 300        
    # {}
  end
    
end
