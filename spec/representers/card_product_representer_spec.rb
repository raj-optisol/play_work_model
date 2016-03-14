require_relative '../../app/representers/card_product_representer'



describe CardProductRepresenter do
  subject {OpenStruct.new.extend(CardProductRepresenter)}
 
  context "for a player" do
    it "works" do
      subject.age = 12
      subject.card_type = :player
      subject.gender = "M"
      subject.amount = 120
      json = JSON.parse(subject.to_json)
      json["age"].should == 12
    end
  end

  context "for a staff" do
    it "works" do
      subject.age = 12
      subject.card_type = :staff
      subject.gender = "M"
      subject.amount = 120
      json = JSON.parse(subject.to_json)
      json["age"].should == "N/A"
    end
  
  end
end
