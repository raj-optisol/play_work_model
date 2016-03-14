require 'spec_helper'

module KyckRegistrar
  module Actions
    describe CreateOrder do

      describe "#new" do
        it "takes a requestor" do
          expect{described_class.new}.to raise_error ArgumentError
        end

        it "takes a payer" do
          expect{described_class.new(User.new)}.to raise_error ArgumentError
        end

        it "takes a payee" do
          expect{described_class.new(User.new, Organization.new)}.to raise_error ArgumentError
        end
      end

      let(:sb) { create_sanctioning_body }
      let(:org) { create_club }
      let(:user) { regular_user }
      let(:admin) { admin_user }

      before :each do
        org.stub(uscs_admin: admin)
      end

      context 'creating cart for user' do
        it 'should create a new order for requestor' do
          input = {kind: :card_request}
          result = described_class.new(user, org, sb).execute(input)
          result.amount.should == 0.0
          result.kind.should == :card_request
          result.status.should == :new
          result.payer_id.to_s.should == org.kyck_id.to_s
          result.payee_id.to_s.should == sb.kyck_id.to_s
          result.assigned_kyck_id.to_s.should == admin.kyck_id.to_s
          result.assigned_name.should == admin.full_name
        end

        it 'should create a new order for requestor when no input is sent' do
          result = described_class.new(user, org, sb).execute({})
          result.kind.should == :card_request
        end
      end

      context 'non-sanctioned organization' do
        before :each do
          org.unstub(:uscs_admin)
        end

        it "sets the assigned fields to default values" do
          input = {kind: :card_request}
          result = described_class.new(user, org, sb).execute(input)
          result.assigned_kyck_id.to_s.should == '00000000-0000-0000-0000-000000000000'
          result.assigned_name.should == 'Not Assigned'
        end
      end

      context 'creating invoice for organization' do
        context 'user has permission' do
          it 'should create a new order for organization' do
            input = {"kind" =>"invoice"}
            result = described_class.new(user, org, sb).execute(input)
            result.amount.should == 0.0
            result.kind.should == :invoice
            result.status.should == :new
            result.payer_id.to_s.should == org.kyck_id.to_s
            result.payee_id.to_s.should == sb.kyck_id.to_s
            result.assigned_kyck_id.to_s.should == admin.kyck_id.to_s
            result.assigned_name.should == admin.full_name
          end
        end
      end

      context 'creating credit for organization' do
        context 'user has permission' do
          it 'should create a new order for organization' do
            requestor = add_user_to_obj(user, sb, {title:"USCS", permission_sets:[PermissionSet::MANAGE_MONEY]})
            input = {"kind" =>"credit"}
            result = described_class.new(requestor, org, sb).execute(input)
            result.amount.should == 0.0
            result.kind.should == :credit
            result.status.should == :new
            result.payer_id.to_s.should == org.kyck_id.to_s
            result.payee_id.to_s.should == sb.kyck_id.to_s
            result.assigned_kyck_id.to_s.should == admin.kyck_id.to_s
            result.assigned_name.should == admin.full_name
          end
        end

        context 'when requestor doesnt have permission' do
          it 'should raise a permission error' do
            input = {"kind" =>"credit"}
            expect{ described_class.new(user, org, sb).execute(input)}.to raise_error KyckRegistrar::PermissionsError
          end
        end
      end
    end
  end
end
