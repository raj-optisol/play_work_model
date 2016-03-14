require 'spec_helper'

module Teams
  describe CompetitionsController do
    include Devise::TestHelpers

    let(:requestor) { regular_user }
    let (:competition){ create_competition }

    before(:each) do
      sign_in_user(requestor)
    end

    context 'for a team' do

    end 
  end
end
