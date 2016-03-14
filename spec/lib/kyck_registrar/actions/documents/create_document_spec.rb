# encoding: UTF-8
require 'spec_helper'

module KyckRegistrar
  module Actions
    describe CreateDocument do
      let(:requestor) { admin_user }
      let(:doc_owner) { regular_user(claimed:false) }
      subject { described_class.new(requestor, doc_owner) }

      describe '#execute' do
        let(:input) do
          {
            kind: 'proof_of_birth',
            url: 'http://images.com/birth.pdf'
          }
        end

        it 'adds a document to the user' do
          expect { subject.execute(input) }.to(
            change { doc_owner.documents.count }.by(1)
          )
        end

        it 'sets the user as the document owner' do
          d = subject.execute(input)
          d.owner.should_not be_nil, 'Document Owner is nil'
          d.owner.kyck_id.should == doc_owner.kyck_id
          Oriented.graph.commit
          d.extend(DocumentRepresenter).to_json
        end

        context 'when certified is the file name' do

          it 'points the doc to the certified on file document' do
            result = subject.execute(file_name: '__kyck__certified')
            result.file_name.should == 'Doc-on-file_vopprg'
            Oriented.graph.commit
            result.extend(DocumentRepresenter).to_json
          end
        end

        it 'marks it as approved' do
          result = subject.execute(file_name: '__kyck__certified')
            Oriented.graph.commit
          result.status.should == :approved
        end

      end

      context 'when an organization id is supplied for a waiver' do
        let(:club) { create_club }
        it 'adds the organization to the document' do
          result = subject.execute(
            organization_id: club.kyck_id, kind: :waiver)
          result.organization.should_not be_nil
            Oriented.graph.commit
          puts result.extend(DocumentRepresenter).to_json
          assert_equal result.organization.kyck_id, club.kyck_id
          assert_equal club.documents.count, 1
        end
      end
    end
  end
end
