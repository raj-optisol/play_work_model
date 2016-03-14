require 'spec_helper'
module KyckRegistrar
  module Actions
    describe AddUser do

      describe "new" do
        it "should take a requestor" do
          expect{described_class.new}.to raise_error ArgumentError
        end

      end

      describe "#execute" do
        subject {described_class.new(requestor)}

        let(:user_attributes) {
          {
            first_name: 'Pebbles', 
            last_name: 'Flintstone',
            email: 'Pebbles@Bedrockisp.com',
            gender: 'F',
            birthdate: 12.years.ago,
            avatar_version: "version",
            avatar_uri: "url"
          } 
        }

        context "when the requestor has the appropriate rights" do
          let!(:requestor) { 
              regular_user
            }

          context "when the user does not exist" do

            it "should create a user" do
              usr = described_class.new(requestor).execute(user_attributes)
              requestor.accounts.count.should == 1
            end

            it "downcases the email" do
              usr = described_class.new(requestor).execute(user_attributes)
              usr.email.should == 'pebbles@bedrockisp.com'
            end

          end


          context "when the user does exist" do
          
            let(:existing_user) { regular_user}
            let(:user_attributes) {{ user_id: existing_user.kyck_id }}
          
            it "should create the player" do
              subject.execute(user_attributes)
              requestor.accounts.count.should == 1              
              requestor.accounts.first.id.should == existing_user.id
            end
          
          end


        end

      end
    end
  end
end
