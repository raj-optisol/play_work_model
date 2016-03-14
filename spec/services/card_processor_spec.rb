# encoding: UTF-8
require 'spec_helper'
class CardProcessor
  describe 'Process' do
    let(:requestor) { regular_user }
    let(:club) { create_club }
    let(:sb) { create_sanctioning_body }
    let(:order) { create_order(requestor, club, sb) }
    let(:card_action) { Object.new }
    
    
    let(:input) { ActiveSupport::HashWithIndifferentAccess.new({name:'order_paid', content: {order_id: order.id, user_id: requestor.kyck_id}}) }
    
    let(:cp) { CardProcessor.new }
    before do
      cp
      card_action.stub(:execute).and_return([])
    end
    it 'should call order_paid method on the Card Processor' do
      
      CardProcessor.stub(:new).and_return(cp)
      cp.should_receive(:order_paid).with(input[:content])
      CardProcessor.process input
    end
    
    it 'should call request cards action' do
      KyckRegistrar::Actions::RequestCards.should_receive(:new) do |u, c|
        u.kyck_id.should == requestor.kyck_id
        c.kyck_id.should == club.kyck_id
        card_action
      end
      CardProcessor.process input
    end

  end
end
