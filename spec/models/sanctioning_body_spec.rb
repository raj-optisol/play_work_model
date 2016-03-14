require 'spec_helper'

describe SanctioningBody do

  subject {SanctioningBody.new}

  it "should have a name" do
    subject.name = 'USCS'

    subject.name.should == 'USCS'
  end

  it "should have a kyck_id" do
    subject.kyck_id = 'this is a kyck_id'

    subject.kyck_id.should == 'this is a kyck_id'
  end

  it "should have a url" do
    subject.url = 'http://usclubsoccer.com'

    subject.url.should == 'http://usclubsoccer.com'
  end

  context "sanctions" do
    it "should have sanctions" do
      subject.sanctions.should == []
    end

    describe "sanctioning an organization" do

      it "adds an organization" do
        o = Organization.build(name: 'New Org', kind: :club)
        expect {
          subject.sanction(o)
        }.to change{subject.sanctions.count}.by(1)
      end

      it "returns a sanction" do
        o = Organization.build(name: 'New Org', kind: :club)
        subject.sanction(o).should be_a(Sanction)
      end
    end

    describe "sanctioning a competition" do
      let(:comp) { create_competition }

      it "adds an competition" do
        expect {
          subject.sanction(comp)
        }.to change{subject.sanctions.count}.by(1)
      end

      it "returns an Sanction" do
        subject.sanction(comp).should be_a(Sanction)
      end
    end
  end

  describe "#create_sanctioning_request_for" do
    let(:sanctioning_body) {create_sanctioning_body}
    let(:club) {create_club}
    let(:user) {regular_user}

    it "creates a request" do
      reg = sanctioning_body.create_sanctioning_request(club, user)
    end
  end

  describe "#card_user_for_organization" do
    let(:sanctioning_body) {create_sanctioning_body}
    let(:club) {create_club}
    let(:user) {regular_user}
    it "creates a card" do
      expect{
        sanctioning_body.card_user_for_organization(user, club)
      }.to change {
        CardRepository.all.count
      }.by(1)
    end
  end
end
