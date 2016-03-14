# encoding: UTF-8
require 'spec_helper'

describe KyckRegistrar::Actions::AddNote do
  let(:sanctioning_body) { create_sanctioning_body }
  let(:org) { create_club }
  let(:note_writer) { regular_user }
  let(:sanctioning_request) do
    create_sanctioning_request(sanctioning_body, org, note_writer)
  end
  let(:admin) { admin_user }

  it 'as regular user and owner of request should create a new note' do
    action = KyckRegistrar::Actions::AddNote.new(note_writer,
                                                 sanctioning_request)
    input = { text: 'THIS IS A NOTE' }
    expect do
      note = action.execute input
    end.to change { sanctioning_request.notes.count }.by(1)
  end

  context 'when the requestor is not the author' do
    let(:requestor) { regular_user }

    subject { described_class.new(requestor, sanctioning_request) }

    context 'but has permission' do
      before do
        add_user_to_org(requestor,
                        sanctioning_body,
                        permission_sets: [PermissionSet::MANAGE_REQUEST])
      end

      it 'adds the note' do
        input = { text: 'THIS IS A NOTE' }
        expect do
          result = subject.execute input
        end.to change { sanctioning_request.notes.count }.by(1)
      end
    end
  end

  it 'as admin should create a new note ' do
    assert_difference proc { sanctioning_request.notes.count } do
      action = KyckRegistrar::Actions::AddNote.new admin, sanctioning_request
      input = { text: 'THIS IS AN ADMIN NOTE' }
      action.execute input
    end
  end
end
