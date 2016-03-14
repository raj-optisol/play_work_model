# encoding: UTF-8
require 'spec_helper'
require 'moqueue'
require_relative '../../services/card_creation_service'

describe CardCreationService do

    let(:rabbit) { MQ.new }
    let(:channel) { Object.new }
    let(:queue) { rabbit.queue('play.order.paid') }
    let(:event_exchange) { rabbit.topic('events') }

    let(:requestor) { regular_user }
    let(:club) { create_club }
    let(:sb) { create_sanctioning_body }
    let(:order) { create_order(requestor, club, sb) }
    let(:input) { {name:'order_paid', content: {order_id: order.id, user_id: requestor.kyck_id}}.to_json }
    let(:processor) { stub_const("CardProcessor", Class.new) }


    before do
      overload_amqp
      reset_broker
      subject.stub(:channel).and_return(channel)
      channel.stub(:queue).and_return(queue)
      channel.stub(:topic).and_return(event_exchange)
      channel.stub(:nack).and_return(true)
      channel.stub(:ack).and_return(true)
      Moqueue::MockHeaders.any_instance.stub(:redelivered?).and_return(false)
      Moqueue::MockHeaders.any_instance.stub(:delivery_tag).and_return(1)
    end

    context "When no errors" do

      it "should read an item from the queue and process it" do
          processor.should_receive(:process).with(JSON.parse(input))

          subject.setup_order_subscriber
          queue.publish(input)

          queue.received_message?(input).should be_true

      end
    end

    context "When errors occur" do

      it "should retry it and then requeue it for processing" do
          processor.should_receive(:process).with(JSON.parse(input)).exactly(2).times.and_throw("ERROR")
          channel.should_receive(:nack).with(1, false, true).exactly(1).times
          subject.setup_order_subscriber
          queue.publish(input)

      end

      it "should not requeue it" do
          Moqueue::MockHeaders.any_instance.stub(:redelivered?).and_return(true)

          processor.should_receive(:process).with(JSON.parse(input)).exactly(2).times.and_throw("ERROR")
          channel.should_receive(:nack).with(1).exactly(1).times

          subject.setup_order_subscriber
          queue.publish(input)

      end
    end
end
