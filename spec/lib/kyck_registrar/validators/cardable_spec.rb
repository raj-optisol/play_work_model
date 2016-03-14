require 'spec_helper'

module KyckRegistrar
  module Validators
    describe Cardable do

      let(:user) {regular_user}
      let(:waiver) {OpenStruct.new(kind: :waiver)}
      let(:pob) {OpenStruct.new(kind: :proof_of_birth)}
      let(:docs) {[waiver, pob]}

      describe "#valid?" do

        context "for a player" do
          context "when the user is cardable" do

            before do
              user.stub(:documents) { docs}
              user.avatar = "avatar"
            end
            it "returns true" do
              described_class.new(user, :player).valid?.should == true
            end
          end

          context "when the user is not cardable" do
            before do
              user.stub(:documents) { docs}
              user.avatar = "avatar"
            end

            it "because the user has no waiver it returns false" do
              user.stub(:documents) { [pob]}
              described_class.new(user, :player).valid?.should == false
            end


            it "because the user has no proof_of_birth it returns false" do
              user.stub(:documents) { [waiver]}
              described_class.new(user, :player).valid?.should == false
            end

          end
        end

        context "for a staff" do

          it "returns true" do
            described_class.new(user, :staff).valid?.should == true
          end
          
        
        end
      end
    end
  end
end
