require 'spec_helper'

describe SanctioningRequest do

  describe "properties" do
    subject {SanctioningRequest.build} 
    it "has a status" do
      subject.status = :pending
      subject.status.should == :pending
    end

    it "has a kind" do
      subject.kind = :sanctioning
      subject.kind.should == :sanctioning
    end

    it "has a payload" do
      subject.payload = {some: "thing", is: "Happening"}
      subject.payload.should == {some: "thing", is: "Happening"}
    end

    it "has a kind" do
      subject.kind = :club
      subject.kind.should == :club
    end

  end

  describe "notes" do
    subject {SanctioningRequest.build( kind: :club, status: :active)}
    let(:note) {Note.build(text: "Buckets")}
    it "can add notes" do
     expect { subject.add_note(note) }.to change {subject.notes.count}.by(1)
    end   

    it "can supply existing notes" do
      subject.add_note(note)
      subject.notes.count.should == 1
      subject.notes.first.id.should == note.id
    end
  end


end
