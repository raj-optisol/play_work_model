require_relative '../../../../lib/kyck_registrar/actions/create_roster'
require_relative '../repositories/organization_memory_repository'

module KyckRegistrar
  module Actions
    describe CreateRoster do
      describe ".new" do
        it "should require a requestor" do
          expect{described_class.new}.to raise_error ArgumentError
        end

        it "should require a team" do
          expect{described_class.new(User.new)}.to raise_error ArgumentError
        end

        it "should not raise an error if arguments are valid" do
          expect{described_class.new(User.new, Team.new)}.to_not raise_error
        end
      end

      describe "#execute" do
        let(:requestor) { regular_user }
        let(:org) { create_club }
        let(:team) { create_team_for_organization(org) }

        context "when the requestor has rights to create a roster" do
          before do
            add_user_to_org(requestor,
                            org,
                            title:"Coach",
                            permission_sets:[PermissionSet::MANAGE_ROSTER])
          end

          subject do
            KyckRegistrar::Actions::CreateRoster.new(requestor, team)
          end
          let(:input) { {name: 'New Roster'} }

          it "creates a roster for the team " do
            roster = subject.execute(input)
            team.rosters.count.should == 1
          end

          it "broadcasts new roster" do
            listener = double('listener')
            listener.should_receive(:roster_created).with instance_of Roster
            subject.subscribe(listener)

            subject.execute(input)
          end

          context "but supplies bad input" do
            it "broadcasts invalid roster" do
              input[:name] = ''
              listener = double('listener')
              listener.should_receive(:invalid_roster).with instance_of Roster
              subject.subscribe(listener)

              subject.execute(input)
            end
          end

          context "for the open team" do
            before do
              team.stub(:open?) { true }
            end

            it "is not allowed" do
              expect { subject.execute(input) }.to raise_error
            end
          end
        end

        context "when the requestor does not have rights" do
          subject {
            KyckRegistrar::Actions::CreateRoster.new(requestor, team)
          }

          it "should raise a PermissionsError" do
            expect{subject.execute(name: 'New Roster')}.to raise_error PermissionsError
          end

        end
      end
    end
  end
end
