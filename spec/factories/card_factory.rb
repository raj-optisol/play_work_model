require 'factory_girl'

FactoryGirl.define do

  factory :card, class: CardData do
    expires_on {1.year.from_now}
    status :approved
    kind :player
    approved_on { Time.now }
  end

end

def create_card(user, club, sb, attrs={})
  card = FactoryGirl.create(:card, attrs)
  card.carded_user = user._data
  card.carded_for = club._data
  card.sanctioning_body = sb._data
  %w(first_name last_name middle_name birthdate).each do |attr|
    card.send("#{attr}=", attrs.fetch(attr, user.send(attr)))
  end
  card.set_duplicate_lookup_hash
  card.save!
  CardRepository.find( card.id)
end
