require 'spec_helper'
module KyckRegistrar
  module Import
    describe ActiveRecordReporter do
      let(:user) { regular_user }
      let(:club) { create_club }
      let(:import_process) do
        ImportProcess.create(
          organization_id: club.kyck_id,
          user_id: regular_user.kyck_id,
          file_name: 'test.csv')
      end 

      describe '#import_started' do
        before do
           stub_wisper_publisher( 'ImportCSV', :execute, :import_started )
        end
        it 'creates an import message for import started' do
          reporter = described_class.new(import_process.kyck_id)
          imp = ImportCSV.new('test', user, [ {id: 'balls'} ], {identifier: import_process.kyck_id})
          imp.reporter = reporter

          expect { imp.execute }.to change {import_process.import_messages.where(kind: :started).count}.by(1)
        end

        it 'creates an import message for import ended' do
          reporter = described_class.new(import_process.kyck_id)
          imp = ImportCSV.new('test', user, [ {id: 'balls'} ], {identifier: import_process.kyck_id})
          imp.reporter = reporter

          expect { imp.execute }.to change {import_process.import_messages.where(kind: :ended).count}.by(1)
        end
      end
    end
  end
end
