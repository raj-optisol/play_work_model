require 'spec_helper'

module KyckRegistrar
  module Actions
    describe CreateAccount do

      let(:valid_account) {{email: 'fred@flintstone.com', first_name: 'Fred', last_name: 'Flintstone' }}
      let(:creator) {User.build(first_name: 'Joe', last_name: 'Admin',kyck_id: "34567",  permission_sets:[PermissionSet::MANAGE_STAFF], kind: 'admin')}
      let(:api_wrapper) {Object.new}
      let!(:account_for_creator) {create_account(kyck_id: creator.kyck_id, kyck_token: "12345") }

      describe "initialize" do

        it "should take a hash of account attributes and a creator id" do
          expect{CreateAccount.new(valid_account, creator, api_wrapper)}.to_not raise_error
        end

        context "with quoted keys" do

          it "should still be valid" do
            quoted_account = {"email" => 'fred@flintstone.com', "first_name"=> 'Fred', "last_name"=> 'Flintstone', permission_sets:[PermissionSet::MANAGE_STAFF]}
            expect{CreateAccount.new(quoted_account, creator, api_wrapper)}.to_not raise_error
          end

        end

        context "with invalid data" do
          [:email, :first_name, :last_name].each do |attr|
            it "should complain if #{attr} is not provided" do
              expect {CreateAccount.new(valid_account.tap {|va| va.delete(attr)}, creator, api_wrapper)}.to raise_error InvalidAttributesError
            end
          end
        end

        context "by a user that does not have the permission to create accounts" do
          it "should raise a permissions error" do
            creator.permission_sets = []
            creator.kind="user"

            expect {CreateAccount.new(valid_account, creator, api_wrapper  )}.to raise_error KyckRegistrar::PermissionsError
          end
        end
      end

      describe "#execute" do
        subject {CreateAccount.new(valid_account, creator, api_wrapper)}

        it "should call put_account on the api" do
          api_wrapper.should_receive(:put_account).with(valid_account).and_return({"id" => "123"})
          subject.execute
        end

        it "should return an account id" do
          api_wrapper.should_receive(:put_account).with(valid_account).and_return({"id" => "123"})
          subject.execute.should == {"id" => "123"}
        end

        context "when the api does not return an 'id'" do
          it "should raise an error" do
            api_wrapper.should_receive(:put_account).with(valid_account).and_return({})
            expect{subject.execute}.to raise_error KyckApiError
          end
        end

        context "when the api returns an unknown error" do
          it "should raise a KyckApiError" do
            api_wrapper.should_receive(:put_account).and_raise(StandardError)
            expect{subject.execute}.to raise_error KyckApiError
          end
        end
      end

      context "when the api is not provided" do
        subject {CreateAccount.new(valid_account, creator)}
        it "should default to KyckApi::Client" do
          subject.api.should be_a(KyckApi::Client)
        end

      end
    end

  end
end
