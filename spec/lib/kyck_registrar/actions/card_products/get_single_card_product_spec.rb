require 'spec_helper'

module KyckRegistrar
  module Actions
    describe GetSingleCardProduct do

      let(:requestor) { regular_user }
      let(:uscs) { create_sanctioning_body }
      let(:club) { create_club }
      let!(:card_product) do 
        create_card_product(uscs, age: 12, card_type: :player, amount: 15)
      end

      describe '#execute' do
        subject { described_class.new(requestor, uscs) }

        before do
          add_user_to_org(requestor,
                          uscs,
                          permission_sets: [PermissionSet::MANAGE_CARD])
        end

        it 'returns the product for the conditions' do
          cp = subject.execute( user: {age: 10}, card_type: :player)
          cp.id.should == card_product.id
        end

        context 'when team is supplied' do
          let(:team) { create_team_for_organization(club) }
          let(:team_admin) { regular_user }
          subject { described_class.new(team_admin, uscs, nil, team) }

          context 'and the requestor has card permissions for the team' do
            before do
              add_user_to_org(team_admin, team, permission_sets: [PermissionSet::REQUEST_CARD])
            end

            it 'returns the product for the conditions' do
              cp = subject.execute({user: {age: 10}, card_type: :player})
              cp.id.should == card_product.id
            end

            context 'and the team is in a competition' do
              let(:comp) { create_competition }
              let(:division) { create_division_for_competition(comp) }

              before do
                create_competition_entry(requestor,
                                         comp,
                                         division,
                                         team,
                                         nil,
                                         status: :approved,
                                         kind: :request)
              end

              context 'and the competition does not have special pricing' do
                it 'returns the uscs product for the conditions' do
                  cp = subject.execute(user: {age: 10}, card_type: :player)
                  cp.id.should == card_product.id
                end

                context 'but the team\'s organization does' do
                  let!(:club_cp) {create_card_product(uscs, age: 12, card_type: :player, amount: 11,organization_id: club.kyck_id )}

                  it 'returns the uscs product for the team\'s organziation' do
                    cp = subject.execute(user: {age: 10}, card_type: :player)
                    cp.id.should == club_cp.id
                  end
                end
              end

              context 'and the competition has special pricing' do
                let!(:comp_cp) {create_card_product(uscs, age: 12, card_type: :player, amount: 11,organization_id: comp.kyck_id )}

                it 'returns the special pricing' do
                  cp = subject.execute(user: {age: 10}, card_type: :player)
                  cp.id.should == comp_cp.id
                end
              end
            end

            context 'when there is special pricing' do


              context 'but not for the requested org' do
                let(:other_club) { create_club}
                let!(:other_card_product) {create_card_product(uscs, age: 12, card_type: :player, amount: 18, organization_id:other_club.kyck_id)}

                subject {described_class.new(team_admin, uscs, club)}
                it 'doesn\'t return that pricing' do
                  cp = subject.execute({user: {age: 10}, card_type: :player})
                  cp.id.should_not == other_card_product.id
                end
              end
            end
          end
        end

        context 'when conditions don\'t match anything' do

          it 'returns nil' do
            cp = subject.execute({user: {age: 14}, card_type: :player}.with_indifferent_access)
            cp.should be_nil
          end

        end
      end
    end
  end
end
