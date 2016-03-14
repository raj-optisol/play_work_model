# encoding: UTF-8
require 'spec_helper'
describe NameRepresenter do
  describe '#to_json' do
    context 'when a roster does not have a team' do
      let(:roster) do
        r = Roster.new
        r.name = 'Roster'
        r.stub(:kyck_id) { '1235' }
        r
      end

      it 'does not include the url' do
        roster.extend(NameRepresenter)
        json = JSON.parse(roster.to_json)
        json.should_not have_key('url')
        json.should have_key('name')
      end
    end
  end
end
