# encoding: UTF-8
require 'spec_helper'

module KyckRegistrar
  module Actions
    describe AddPlayer do
      describe 'new' do
        it 'should take a requestor' do
          expect do
            AddPlayer.new
          end.to raise_error ArgumentError
        end

        it 'should take a playable' do
          expect do
            AddPlayer.new(User.new)
          end.to raise_error ArgumentError
        end
      end

      describe '#execute' do

        let(:location_attributes) do
          {
            address1: "1 Test Ave",
            city: "Testville",
            state: "NC",
            zipcode: "11111"
          }
        end

        let(:player_data) do
          {
            first_name: "Test",
            middle_name: "Test",
            last_name: "User",
            email: "test@test.com",
            gender: :male,
            birthdate: 9.years.ago.to_date,
            position: "Middle",
            jersey_number: 1,
          }
        end

        context "required location_data" do
          
          let(:org) { create_club }
          let(:player_attributes) do
            {
              first_name: "Test",
              middle_name: "Test",
              last_name: "User",
              email: "test@test.com",
              gender: :male,
              birthdate: 9.years.ago.to_date,
              position: "Middle",
              jersey_number: 1,
            }.merge(location_attributes).with_indifferent_access
          end
          let(:requestor) { admin_user }

          before(:each) do
            u = UserRepository.find_by_email(player_attributes[:email])
            UserRepository.delete(u) if u
            add_user_to_org(
              requestor,
              org,
              {
                title: 'Coach',
                permission_sets: [PermissionSet::MANAGE_PLAYER]
              },
              UserRepository)
          end

          subject { AddPlayer.new(requestor, org) }

          context "with invalid data" do
            it "broadcasts a player invalid message" do
              listener = double('listener')
              listener.should_receive(:invalid_player).with(instance_of Player)
              subject.subscribe(listener)
              player_attributes.delete(:address1)
              player_attributes.delete(:city)
              subject.execute(player_attributes)
            end

            context "with valid data" do
              it "broadcasts a player created" do
              listener = double('listener')
              listener.should_receive(:player_created).with(instance_of Player)
              subject.subscribe(listener)
              subject.execute(player_attributes)
              end
            end
          end
        end
        
        context "document data" do
          let(:org) { create_club }
          let(:requestor) { admin_user }

          before(:each) do
            u = UserRepository.find_by_email(player_attributes[:email])
            UserRepository.delete(u) if u
            add_user_to_org(
              requestor,
              org,
              {
                title: 'Coach',
                permission_sets: [PermissionSet::MANAGE_PLAYER]
              },
              UserRepository)
          end

          subject { AddPlayer.new(requestor, org) }


          context "avatar" do

            let(:player_attributes) do
              {
                avatar: "test_avatar",
                avatar_uri: "https://www.avatars.com/test/1",
                avatar_version: 1
              }.merge(location_attributes).merge(player_data).with_indifferent_access
            end
            
            it "sets the avatar of the user" do
              subject.execute(player_attributes)
              u = UserRepository.find_by_email(player_attributes[:email])
              expect(u.avatar?).to be_true
            end
          end

          context "any other document type" do
            let(:player_attributes) do
              {
                documents: {
                  birth_certificate: {
                    title: "test_birth_certificate",
                    url: "http://www.birth-certificates.com/test/1",
                    kind: "proof_of_birth",
                    status: "approved",
                    file_name: "afilename",
                    thumbnail: "https:///www.birth-certificate.com/thumbnail/1"
                  }
                }
              }.merge(location_attributes).merge(player_data).with_indifferent_access
            end

            it "saves the document and associates it with the new player" do
              subject.execute(player_attributes)
              u = UserRepository.find_by_email(player_attributes[:email])
              expect(u.documents.count).to eq(1)
              expect(u.documents.first.kind).to eq(:proof_of_birth)
            end
          end
        end

        context 'player email supplied, parent email not supplied' do
          let(:org) { create_club }
          let(:player_attributes) do
            {
              first_name: 'Pebbles',
              middle_name: 'BamBam',
              last_name: 'Flintstone',
              email: 'pebbles@bedrockisp.com',
              gender: :female,
              birthdate: 9.years.ago.to_date,
              position: 'Middie',
              jersey_number: 23
            }.merge(location_attributes).with_indifferent_access
          end

          context 'for an organization' do
            subject { AddPlayer.new(requestor, org) }

            context 'when the requestor has the appropriate rights' do
              let(:requestor) { regular_user }
              before(:each) do
                u = UserRepository.find_by_email(player_attributes[:email])
                UserRepository.delete(u) if u
                add_user_to_org(
                  requestor,
                  org,
                  {
                    title: 'Coach',
                    permission_sets: [PermissionSet::MANAGE_PLAYER]
                  },
                  UserRepository)
              end

              context 'and params are valid' do
                it 'broadcasts a player created' do
                  listener = double('listener')
                  listener.should_receive(:player_created).with(
                    instance_of Player)
                  subject.subscribe(listener)
                  subject.execute(player_attributes)
                end

                it 'gives the player a position' do
                  result = subject.execute(player_attributes)
                  result.position.should == 'Middie'
                end

                context 'when the user does not exist' do
                  it 'should create a user' do
                    expect do
                      subject.execute(player_attributes)
                    end.to change { UserRepository.all.count }.by(1)
                  end

                  it 'creates the user with the right attributes' do
                    p = subject.execute(player_attributes)
                    %w(first_name last_name middle_name gender birthdate).each do |attr|
                      p.user.send(attr).should == player_attributes[attr]
                    end
                    p.user.email.should == player_attributes[:email]
                  end
                end

                context 'when the user does exist' do
                  let(:existing_user) do
                    regular_user(birthdate: 9.years.ago.to_date)
                  end
                  let(:player_attributes) do
                    { user_id: existing_user.kyck_id }
                  end

                  it 'should create the player' do
                    result = subject.execute(player_attributes)
                    assert_equal result.user.email, existing_user.email
                    assert_equal(result.user.first_name,
                                 existing_user.first_name)
                    assert_equal(result.user.middle_name,
                                 existing_user.middle_name)
                    assert_equal(result.playable.kyck_id,
                                 org.open_team.official_roster.kyck_id)
                  end

                  context "and a team id is provided" do
                    let(:team) { create_team_for_organization(org) }
                    let!(:roster) { create_roster_for_team(team, official: true) }
                    before do
                      player_attributes[:team] = team.kyck_id
                    end
                    it "adds the player to the team" do
                      result = subject.execute(player_attributes.with_indifferent_access)
                      assert_equal result.playable.kyck_id, team.official_roster.kyck_id
                    end
                  end
                end
              end  # params are valid

              context 'and params are not valid' do

                it 'broadcasts invalid player' do
                  player_attributes.delete(:first_name)
                  listener = double('listener')
                  listener.should_receive(:invalid_player).with(
                    instance_of(Player))
                  subject.subscribe(listener)
                  subject.execute(player_attributes)
                end
              end # and params are not valid
            end  # when requestor has rights

            context 'when the requestor does not have the rights' do
              let!(:requestor) { regular_user }

              it 'should raise a permissions error' do
                expect do
                  subject.execute(player_attributes)
                end.to raise_error PermissionsError
              end
            end
          end

          context 'for a roster' do
            let(:team) { create_team_for_organization(org, born_after: (Date.today - 13.years)) }
            let(:roster) { create_roster_for_team(team, official: true) }
            subject { described_class.new(requestor, roster) }
            let(:requestor) { regular_user }
            let(:input) do
              { 'first_name' => 'Logan',
                'middle_name' => 'Nicklaus',
                'last_name' => 'Goodrich',
                'email' => 'logan@goodrichs.net',
                'phone_number' => '7045442065',
                'birthdate' => (Date.today - 12.years).to_s,
                'gender' => :male,
                'position' => 'Right Wing',
                'jersey_number' => '10',
                'user_id' => '' }.merge(location_attributes).with_indifferent_access
            end

            before do
              add_user_to_org(
                requestor,
                org,
                {
                  title: 'Coach',
                  permission_sets: [PermissionSet::MANAGE_PLAYER]
                },
                UserRepository)
            end

            context 'when the user does exist' do
              let(:existing_user) do
                regular_user(birthdate: 12.years.ago.to_date)
              end
              let(:player_attributes) { { user_id: existing_user.kyck_id } }

              it 'should create the player' do
                expect do
                  result = subject.execute(player_attributes)
                  assert_equal result.user.email, existing_user.email
                  assert_equal result.user.first_name, existing_user.first_name
                  org.open_team._data.reload
                end.to change { roster.players.count }.by(1)
              end

              context 'and the player is on the open roster' do
                before do
                  p = org.open_team.add_player(existing_user)
                  p._data.save
                end

                it 'removes them from the open roster' do
                  assert !org.open_team.official_roster.get_player_for_user(existing_user).nil?
                  result = subject.execute(player_attributes)
                  Oriented.graph.commit
                  assert_equal org.open_team.official_roster.players.count, 0
                end
              end
            end

            it 'broadcasts a player created' do
              listener = double('listener')
              listener.should_receive(:player_created).with instance_of Player
              subject.subscribe(listener)
              subject.execute(input)
            end
          end
        end

        context 'parent email supplied, player email not supplied' do
          let(:requestor) { regular_user }
          let(:org) { create_club }

          let(:input) do
            { 'first_name' => 'Logan',
              'middle_name' => 'Nicklaus',
              'last_name' => 'Goodrich',
              'parent_email' => 'Glenn@goodrichs.net',
              'phone_number' => '7045442065',
              'birthdate' => (Date.today - 12.years).to_s,
              'gender' => :male,
              'position' => 'Right Wing',
              'jersey_number' => '10',
              'user_id' => '' }.merge(location_attributes).with_indifferent_access
          end

          subject { AddPlayer.new(requestor, org) }

          before do
            add_user_to_org(
              requestor, org,
              {
                title: 'Coach',
                permission_sets: [PermissionSet::MANAGE_PLAYER]
              },
              UserRepository)
          end

          it 'creates the parent user' do
            subject.execute(input)
            parent = UserRepository.find_by_email(
              input[:parent_email].downcase)
            assert_equal parent.first_name, 'Parent'
            assert_equal parent.last_name, input[:last_name]
          end

          it 'downcases the email' do
            subject.execute(input)
            parent = UserRepository.find_by_email(
              input[:parent_email].downcase)
            assert_equal parent.first_name, 'Parent'
            assert_equal parent.last_name, input[:last_name]
          end

          it 'creates the player user with the right attributes' do
            p = subject.execute(input)
            %w(first_name last_name middle_name gender).each do |attr|
              p.user.send(attr).should == input[attr]
            end

            assert_equal(p.user.birthdate,
                         Date.strptime(input[:birthdate], '%Y-%m-%d'))
            assert_match p.user.email, /kyckfake/
          end
        end

        context 'both parent email and player email supplied' do
          let(:requestor) { regular_user }
          let(:org) { create_club }

          let(:input) do
            { 'first_name' => 'Logan',
              'middle_name' => 'Nicklaus',
              'last_name' => 'Goodrich',
              'parent_email' => 'Glenn@goodrichs.net',
              'email' => 'logan@goodrichs.net',
              'phone_number' => '7045442065',
              'birthdate' => (Date.today - 12.years).to_s,
              'gender' => :male,
              'position' => 'Right Wing',
              'jersey_number' => '10',
              'user_id' => '' }.with_indifferent_access
          end

          subject { AddPlayer.new(requestor, org) }

          before do
            add_user_to_org(
              requestor,
              org,
              {
                title: 'Coach',
                permission_sets: [PermissionSet::MANAGE_PLAYER]
              },
              UserRepository)
          end

          it 'creates the parent user' do
            subject.execute(input)
            parent = UserRepository.find_by_email(input[:parent_email])
            assert_equal parent.first_name, 'Parent'
            assert_equal parent.last_name, input[:last_name]
          end

          it 'creates the player user with the right attributes' do
            p = subject.execute(input)
            %w(first_name last_name middle_name gender).each do |attr|
              p.user.send(attr).should == input[attr]
            end

            assert_equal(
              p.user.birthdate,
              Date.strptime(input[:birthdate], '%Y-%m-%d'))
            assert_equal p.user.email, input[:email]
          end

          it 'adds the player to the club' do
            expect do
              subject.execute(input)
              Oriented.graph.commit
              org.open_team._data.reload
            end.to change { org.open_team.get_players.count }.by(1)
          end

          it 'adds the player user to the parent user' do
            subject.execute(input)
            parent = UserRepository.find_by_email(input[:parent_email])
            player = UserRepository.find_by_email(input[:email])
            parent.accounts.map(&:kyck_id).should include(player.kyck_id)
          end

          it 'makes the parent an owner of the player' do
            subject.execute(input)
            parent = UserRepository.find_by_email(input[:parent_email])
            player = UserRepository.find_by_email(input[:email])
            player.owners.map(&:kyck_id).should include(parent.kyck_id)
          end

        end
      end
    end
  end
end
