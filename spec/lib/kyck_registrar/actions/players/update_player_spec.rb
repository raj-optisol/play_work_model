require 'spec_helper'

module KyckRegistrar
  module Actions
    describe UpdatePlayer do
      let(:location_attributes) do
        {
          name: "Home",
          address1: "1 Test Street",
          city: "Testville",
          state: "NC",
          zipcode: "11111"
        }
      end
      let(:requestor) {regular_user}
      let(:org) {create_club}
      let(:team) {create_team_for_organization(org)}
      let(:roster) {create_roster_for_team(team)}
      let(:player) {
        p = org.add_player(regular_user(:birthdate => 12.years.ago.to_date), {position: 'Goalkeeper', jersey_number: '10'})
        l = LocationRepository.persist(Location.build(location_attributes))
        p.user.add_location(l)
        UserRepository.persist p.user
        Oriented.graph.commit
        p
      }

      describe "#initialize" do
        it "takes a requestor, an org, and a player" do
          expect {described_class.new(requestor, roster, player.kyck_id)}.to_not raise_error ArgumentError
        end
      end

      describe "#execute" do
        context "when the user has permission" do
          subject {described_class.new(requestor, org, player.kyck_id)}
          before(:each) do
            org.add_staff(requestor, {title: 'Coach', permission_sets: [PermissionSet::MANAGE_PLAYER]})
            UserRepository.persist requestor
          end

          it "updates the player" do
            p = subject.execute({position: 'Middie', jersey_number: '11'})
            p.position.should == 'Middie'
          end

          it "broadcasts the player_updated message" do
            listener = double("listener")
            listener.should_receive(:player_updated).with(instance_of(Player))
            subject.subscribe(listener)
            subject.execute({middle_name: 'Herb', position: 'Middle'})
          end

          context "and the player user is not claimed" do
            it "updates the user" do
              p = subject.execute({middle_name: 'Herb', position: 'Middie', jersey_number: '11', first_name: 'Bob'})
              p.user.first_name.should == "Bob"
              p.user.middle_name.should == "Herb"
            end
          end

          context "when the player record is not found" do

            it "raises an error" do
              expect { described_class.new(requestor, org, "not-a-real-player") }.to raise_error KyckRegistrar::Actions::PlayableAction::PlayerNotFound
            end

          end

          context "when the location data is incomplete" do

            context "and the user already has location data" do

              it "updates the user" do
                p = subject.execute({middle_name: 'Herb', position: 'Middie', jersey_number: '11', first_name: 'Bob'})
                p.user.first_name.should == "Bob"
                p.user.middle_name.should == "Herb"
              end
            end

            context "and the user does not have any location data" do

              let(:player2) {
                p = org.add_player(regular_user(:birthdate => 12.years.ago.to_date), {position: 'Goalkeeper', jersey_number: '10'})
                UserRepository.persist p.user
                Oriented.graph.commit
                p
              }
              
              subject {described_class.new(requestor, org, player2.kyck_id)}

              it "does not update the player" do
                listener = double('listener')
                listener.should_receive(:invalid_player).with(
                  instance_of(Player))
                subject.subscribe(listener)
                subject.execute({middle_name: "Herb", position: "Middle"})
              end
            end
          end

          context "parent email supplied" do

            it "adds the parent email user as a owner of the player" do
              p = subject.execute({parent_email: "testparent@test.com"})
              expect(p.user.owners.count).to eq(1)
              expect(p.user.owners.first.email).to eq("testparent@test.com")
            end

          end

        end
      end
    end
  end
end
