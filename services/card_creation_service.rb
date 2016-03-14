class CardCreationService
  DEFAULT_RETRY_TIMEOUT = 60

  def initialize(opts = {})
    @retries_left = @max_retries = opts['max_retries'] || -1
    @retry_timeout = opts['retry_timeout'] || DEFAULT_RETRY_TIMEOUT
  end

  def start
    Thread.new { run }
  end

  def stop
    connection.close if connection && !connection.closed?
  end


  def run
    puts "RabbitMQ Service starting..." 
    begin
      raise "No RabbitMQ channel" unless channel
      setup_order_subscriber
    rescue => ex
      puts "** RABBITMQ ERROR #{ex.inspect}"
      @retries_left -= 1 if @retries_left > 0
      if @retries_left != 0
        sleep(@retry_timeout)
        retry
      end
    end
  end

  
  def setup_order_subscriber
    q = channel.queue('play.order.paid', durable: true, arguments:{'x-dead-letter-exchange' => "errors"})
    q.bind(event_exchange, routing_key: 'order.paid').subscribe(ack: true) do |meta, payload|
      @retryprocesscnt = 2  
      begin
        evt = JSON.parse(payload)
        result = CardProcessor.process(evt)
        Rails.logger.info("UNPROCESSED Message: #{evt}") if result.nil?
        channel.ack(meta.delivery_tag)
      rescue => e
        @retryprocesscnt -= 1 if @retryprocesscnt > 0
        if @retryprocesscnt != 0
          retry
        end

        if meta.redelivered?
          Raven.capture_message("#{e.inspect} :: SENT to DLX")
          channel.nack(meta.delivery_tag)
        else
          Raven.capture_message("#{e.inspect} :: RE-QUEUED ")
          channel.nack(meta.delivery_tag, false, true)
        end
      end  # End begin
    end # End Subscribe
  end



  private

  def connection
    if (!@conn || @conn.closed?)
      @conn ||= MarchHare.connect(Settings.rabbitmq)
    end
    @conn
  end

  def channel
    return unless connection
    @channel ||= connection.create_channel
  end

  def event_exchange
    @event_exchange ||= channel.topic('events', durable: true)
  end

end
