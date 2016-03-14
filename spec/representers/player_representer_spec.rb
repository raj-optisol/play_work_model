# encoding: UTF-8
require 'spec_helper'

describe PlayerRepresenter do
  let(:org) { create_club }
  let(:team) { create_team_for_organization(org) }
  let(:roster) { create_roster_for_team(team) }
  let(:player_user) { regular_user }

  before(:each) {
    @player = roster.add_player(player_user)
    UserRepository.persist player_user
  }

  describe '#.to_json' do
    subject{ JSON.parse(@player.extend(PlayerRepresenter).to_json)}

    %w(first_name last_name email phone_number).each do |attr|
      it "includes the #{attr}" do
        subject[attr].should == player_user.send(attr)
      end
    end

    it 'includes the playable' do
      subject['playable_item']['id'].should == team.kyck_id.to_s
    end

    it 'includes the phone number' do
      subject['phone_number'].should == player_user.phone_number
    end

    describe 'waiver' do
      context 'when the player has a waiver' do
        before do
          create_document_for_user(player_user, kind: :waiver)
        end

        it 'returns the waiver' do
          subject['waiver']['id'].should_not be_blank
        end

        context 'when the org id is supplied' do
          subject{ JSON.parse(@player.extend(PlayerRepresenter).to_json(organization_id: '12343'))}
          context 'and it does not match the passed in org id' do
            it 'returns the waiver' do
              subject['waiver']['id'].should_not be_blank
            end
          end

          context 'and it does match the passed in org id' do
            let(:club) { create_club }
            let(:doc) { create_document_for_user(player_user, kind: :waiver) }
            subject{ JSON.parse(@player.extend(PlayerRepresenter).to_json(organization_id: club.kyck_id))}
            before do
              club.add_document(doc)
              club._data.save
              doc._data.save!
            end

            it 'returns the waiver' do
              subject['waiver']['id'].should == doc.kyck_id
            end
          end
        end
      end
    end
  end
end
