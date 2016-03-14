require 'spec_helper'

describe PaymentHandler do
  
  
  describe "Update SanctioningRequest Status" do
    let(:requestor) { regular_user }
    let(:sb) { create_sanctioning_body }
    let(:org) { create_club }    
    let(:order) {
      create_order(requestor, org, sb, {kind: :sanctioning_request, amount: 1000.0})
    }
    let!(:sanctioning_request) { create_sanctioning_request(sb, org, requestor, {status: :pending_payment, kind: :club, order_id:order.id})}
    
        
    subject { PaymentHandler.new }

    it "sets sanctioning_request to pending " do

      res = subject.sanctioning_request_deposit_made(order)      
      sr = SanctioningRequestRepository.find(sanctioning_request.id)      
      sr.status.should == :pending
    end
    
  end  
end
