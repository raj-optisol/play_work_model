require 'spec_helper'


describe KyckRegistrar::Actions::UpdateSanctioningRequest do

  let(:repository){ SanctioningRequestRepository}
  let(:club) {create_club}
  let(:uscs) {create_sanctioning_body}
  let(:issuer) {regular_user}

  let(:sanctioning_request) {create_sanctioning_request(uscs, club, issuer )}


  let(:input) {
    {"payload"=>
     {"number_of_players_male_U11"=>"100", 
      "number_of_players_male_U12"=>"1001", 
      "number_of_players_male_adult"=>"100", 
      "number_of_players_female_U11"=>"200", 
      "number_of_players_female_U12"=>"1001", 
      "number_of_players_female_adult"=>"1011"}
    }.with_indifferent_access
  }

  subject { described_class.new(issuer, sanctioning_request)}

  it 'should update an sanctioning request attr object ' do
    result = subject.execute(input)
    result.payload.should == input["payload"].to_json
  end

  
end
