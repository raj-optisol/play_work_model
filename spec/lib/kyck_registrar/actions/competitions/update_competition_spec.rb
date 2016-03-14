require 'spec_helper'

module KyckRegistrar
  module Actions
    describe UpdateCompetition do
      let(:requestor) { regular_user }
      let(:org) { create_club }
      let(:competition) { create_competition}

      describe "initialize" do
        it "takes a requestor and a competition" do
          expect{ described_class.new(requestor, competition)}.to_not raise_error
        end
      end

      describe "execute" do
        subject {described_class.new(requestor, competition)}

        context "when the user has permission" do

          before(:each) do
            competition.add_staff(requestor, title: "Admin", permission_sets: [PermissionSet::MANAGE_COMPETITION])
            UserRepository.persist requestor
          end

          it "updates the competition" do
            result = subject.execute({name: 'New Comp Name'}.with_indifferent_access)
            result.name.should == "New Comp Name"
          end

          it "updates the end date" do
            result = subject.execute({end_date: '9/18/2013'}.with_indifferent_access)
            Time.at(result.end_date).to_date.should == DateTime.parse('2013-09-18')
          end

          it "updates the avatar" do
            result = subject.execute({avatar: 'image'}.with_indifferent_access)
            result.avatar.should == "image"
          end
        end

        context "when the user does not have permission" do

          it "raises an error" do
            expect {subject.execute(name: 'New Comp Name')}.to raise_error PermissionsError
          end

        end
      end
    end

  end
end
