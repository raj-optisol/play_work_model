require 'spec_helper'

module KyckRegistrar
  module Actions
    describe CreateCompetition do
      describe '#new' do
        it 'takes a requestor' do
          expect { described_class.new }.to raise_error ArgumentError
        end
      end

      describe '#execute' do
        let(:competition_params) {
          {
            name: 'The Comp 1',
            kind: 'league',
            level: 'youth_competitive',
            registration_deadline: 2.weeks.ago.strftime('%m/%d/%Y'),
            start_date: DateTime.now.strftime('%m/%d/%Y'),
            end_date: (DateTime.now+6.months).strftime('%m/%d/%Y')}
        }

        let(:requestor) { regular_user }

        subject {KyckRegistrar::Actions::CreateOrganization.new( requestor ) }

        it 'creates a new competition' do
          expect do
            described_class.new(requestor).execute(competition_params)
            Oriented.graph.commit
          end.to change { CompetitionRepository.count }.by(1)
        end

        it 'creates a competiton wiht the right name' do
          result = described_class.new(requestor).execute(competition_params)
          result.name.should == competition_params[:name]
        end

        it 'adds the requestor to the staff' do
          result = described_class.new(requestor).execute(competition_params)
          result.staff.map(&:kyck_id).should include(requestor.kyck_id)
        end

        it 'the requestor can add staff' do
          result = described_class.new(requestor).execute(competition_params)
          assert requestor.can_manage?(result, [PermissionSet::MANAGE_STAFF])
        end

        it "broadcasts a success message" do
          listener = double('listener')
          expect(listener).to receive(:competition_created)
          subject.subscribe(listener)
          subject.execute(competition_params)
        end
      end
    end
  end
end
