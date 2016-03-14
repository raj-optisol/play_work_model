# encoding: UTF-8
require 'spec_helper'

describe NotesController do
  include Devise::TestHelpers
  let(:requestor) { regular_user }
  let(:club) { create_club }
  let(:uscs) { create_sanctioning_body }
  let(:card) { create_card(regular_user, club, uscs) }

  before do
    sign_in_user(requestor)
  end

  describe '#create' do
    let(:note_params) do
      {
        text: 'Test'
      }.with_indifferent_access
    end

    let(:note) do
      card.create_note(text: 'Test', author: requestor)
    end

    it 'calls the add note action' do
      action = mock_execute_action(
        KyckRegistrar::Actions::AddNote,
        note_params,
        note)

      action.stub(:subscribe)

      CardHandler.any_instance.stub(:note_added_to_card)

      post :create, card_id: card.kyck_id, note: note_params, format: :json
    end
  end
end
