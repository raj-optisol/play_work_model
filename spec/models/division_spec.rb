require 'spec_helper'

describe Division do
  let!(:comp) { create_competition }
  subject { div = create_division_for_competition(comp) }

  it "has a name, age, gender, kind, and roster_lock_date" do
    subject.name.should be_present
    subject.age.should be_present
    subject.gender.should be_present
    subject.kind.should be_present
    subject.roster_lock_date.should be_present
  end
end
