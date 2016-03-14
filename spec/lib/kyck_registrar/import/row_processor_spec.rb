# encoding: UTF-8
require 'spec_helper'

module KyckRegistrar
  module Import
    describe RowProcessor do
      let(:club) { create_club }
      describe '#intialize' do
        it 'takes a club' do
          expect { described_class.new(club) }.to_not raise_error
        end
      end

      describe 'process' do
        subject { described_class.new(club) }
        context 'for a player row' do
          let(:valid_player) do
            {
              first_name: 'Bob',
              last_name:  'Barker',
              player_email:      'bob@pir.com',
              position:   'Keeper',
              kind:       'player',
              gender:     'male',
              birthdate:  '2001/01/04',
              phone_number: '777-333-3333',
              jersey_number: '34'

            }
          end
          context 'that does not specify team' do
            it 'adds the player to the club' do
              expect do
                subject.process(valid_player)
                Oriented.graph.commit
              end.to change { club.players.count }.by(1)
            end

            it 'adds the user with the user attributes' do
              player = subject.process(valid_player)
              [:first_name, :last_name, :gender, :phone_number].each do |k|
                player.user.send(k).to_s.should == valid_player[k]
              end
              assert_equal(player.user.birthdate.to_date,
                           valid_player[:birthdate].to_date)
            end
          end

          context 'that specifies team' do
            let(:valid_player) do
              {
                first_name: 'Bob',
                last_name:  'Barker',
                player_email:      'bob@pir.com',
                position:   'Keeper',
                kind:       'player',
                gender:     'male',
                birthdate:  '2001/01/04',
                phone_number: '777-333-3333',
                jersey_number: '34',
                team_name: 'U-14 Boys'
              }
            end
            it 'adds the player to the club' do
              expect do
                subject.process(valid_player)
                OrganizationRepository::TeamRepository.find_by_attrs(
                  conditions: { name: 'U-14 Boys' }).first
              end.to change { club.players.count }.by(1)
            end

            it 'creates the team' do
              expect { subject.process(valid_player) }.to(
                change { club.teams.count }.by(1)
              )
            end

            it 'adds the player to  the team' do
              player = subject.process(valid_player)
              t = OrganizationRepository::TeamRepository.find(name: 'U-14 Boys')
              player.user.plays_for.map(&:kyck_id).should(
                include(t.official_roster.kyck_id)
              )
            end
          end

          context 'that specifies parent email only' do
            let(:valid_player) do
              {
                first_name: 'Bob',
                last_name:  'Barker',
                parent_email:      'bob@pir.com',
                position:   'Keeper',
                kind:       'player',
                gender:     'male',
                birthdate:  '2001/01/04',
                phone_number: '777-333-3333',
                jersey_number: '34',
                team_name: 'U-14 Boys'

              }
            end

            it 'creates the parent user' do
              subject.process(valid_player)
              Oriented.connection.commit
              parent = UserRepository.find_by_email('bob@pir.com')
              parent.should_not be_nil
              parent.first_name.should == 'Parent'
            end

            it 'creates the kid sub account' do
              subject.process(valid_player)
              Oriented.connection.commit
              parent = UserRepository.find_by_email('bob@pir.com')
              child = parent.accounts.first
              child.should_not be_nil
              child.full_name.should == 'Bob Barker'
            end

            context 'when a location is supplied' do
              let(:valid_player) do
                {
                  first_name: 'Bob',
                  last_name:  'Barker',
                  parent_email: 'bob@pir.com',
                  position:   'Keeper',
                  kind:       'player',
                  gender:     'male',
                  birthdate:  '2001/01/04',
                  phone_number: '777-333-3333',
                  jersey_number: '34',
                  team_name: 'U-14 Boys',
                  address1: '123 Main',
                  city: 'Charlotte',
                  state: 'NC',
                  zipcode: '22222'

                }
              end

              it 'adds the location to the parent' do
                subject.process(valid_player)
                Oriented.connection.commit

                parent = UserRepository.find_by_email('bob@pir.com')
                parent.locations.first.address1.should == '123 Main'
              end

              it 'adds the location to the kid' do
                subject.process(valid_player)
                Oriented.connection.commit
                parent = UserRepository.find_by_email('bob@pir.com')
                child = parent.accounts.first
                loc = child.locations.first
                assert_equal child.locations.first.address1, '123 Main'
                ploc = parent.locations.first
                loc.kyck_id.should == ploc.kyck_id
              end
            end
          end
        end

        context 'when a user is invalid' do
          let(:invalid_player) do
            {
              first_name: 'Bob',
              last_name:  'Barker',
              player_email: 'bob@pir.com',
              position:   'Keeper',
              kind:       'player',
              gender:     'Male',
              birthdate:  '2001/01/04',
              phone_number: '777-333-3333',
              jersey_number: '34'
            }
          end

          context 'b/c of Y2K' do
            before do
              invalid_player[:birthdate] = '01/07/00'
            end

            it 'imports properly' do
              subject.process(invalid_player)
              Oriented.connection.commit
              player = UserRepository.find_by_email('bob@pir.com')
              assert_equal(player.birthdate, Date.new(2000, 01, 07))
            end
          end

          context 'due to invalid gender' do
            it 'fixes the gender' do
              subject.process(invalid_player)
              Oriented.connection.commit
              player = UserRepository.find_by_email('bob@pir.com')
              assert_equal(player.gender, :male)
            end
          end

          context 'b/c the parent and user email are the same' do
            before do
              invalid_player[:parent_email] = invalid_player[:player_email]
            end

            it 'ignores the player email' do
              subject.process(invalid_player)
              Oriented.connection.commit
              parent = UserRepository.find_by_email('bob@pir.com')
              assert_not_nil(parent)
              assert_equal(parent.accounts.size, 1, 'Subaccount not created')
            end
          end

          context 'when the kind is capitalized' do
            before do
              invalid_player[:kind] = 'Player'
            end

            it 'handles the kind properly' do
              subject.process(invalid_player)
              Oriented.connection.commit
              player = UserRepository.find_by_email('bob@pir.com')
              assert_not_nil player
            end
          end
        end
      end
    end
  end
end
