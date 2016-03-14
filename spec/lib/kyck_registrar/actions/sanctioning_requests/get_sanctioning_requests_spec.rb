require 'spec_helper'


module KyckRegistrar
  module Actions
    describe GetSanctioningRequests do

      let(:sanctioning_body) {create_sanctioning_body}
      let(:requestor) { regular_user}
      let(:admin_requestor) { admin_user}

      describe "#initialize" do
        it "takes a requestor and an organization" do
          expect{described_class.new(requestor, sanctioning_body)}.to_not raise_error  
        end
      end

      describe "#execute" do
        let(:org) {create_club}
        let(:org2) {create_club}

        let(:request1) { create_sanctioning_request(sanctioning_body, org, requestor ) }

        let(:request2) { create_sanctioning_request(sanctioning_body, org2, admin_requestor, {status:  :approved }) }

        before(:each) do
          @request1 = request1
          @request2 = request2
        end

        context "for a sanctioning body" do

          context 'as a Sanctioning Body admin with permission' do
            subject {KyckRegistrar::Actions::GetSanctioningRequests.new requestor, sanctioning_body}

            before(:each) do
              s = sanctioning_body.add_staff(requestor, {title: 'Admin', permission_sets: [PermissionSet::MANAGE_REQUEST]})
              UserRepository.persist! requestor
            end

            it 'returns all sanctioning requests' do
              input = {}

              result = subject.execute input
              result.count.should == 2

            end

            context "when conditions are supplied" do
              it 'returns requests based on conditions ' do
                input = {:conditions => {:status => 'pending' }}
                result = subject.execute input
                result.count.should == 1
              end
            
            end

          end

          context 'as a user with no permission' do
            subject {KyckRegistrar::Actions::GetSanctioningRequests.new requestor, sanctioning_body}
          
            it 'should raise an error' do
          
              expect{subject.execute({})}.to raise_error PermissionsError
          
            end
          end
        end

        context "for an organization body" do
        
          context 'as a Organization admin with permission' do
            subject {KyckRegistrar::Actions::GetSanctioningRequests.new requestor, org}
        
            before(:each) do
              org.add_staff(requestor, {title: 'Admin', permission_sets: [PermissionSet::MANAGE_REQUEST]})
              UserRepository.persist requestor
            end
        
            it 'should return all pending organization request objects ' do
              input = {:conditions => {:status => 'pending' }}
        
              result = subject.execute input
        
              result.count.should == 1
        
            end
        
            it 'should return an sanctioning request object with all details ' do
              input = {}
              result = subject.execute input
              result.first.status.should == :pending
              result.first.id.should == request1.id
        
            end
          end
        
          context 'as a user with no permission' do
            subject {KyckRegistrar::Actions::GetSanctioningRequests.new requestor, sanctioning_body}
        
            it 'should raise an error' do
        
              expect{subject.execute({})}.to raise_error PermissionsError
        
            end
          end
        end
      end
    end
  end
end
