require 'spec_helper'

describe NotesCell do

  let(:requestor) { regular_user}
  let(:sb) {create_sanctioning_body}
  let(:club) {create_club}
  let(:sanctioning_request) { create_sanctioning_request(sb, club, requestor )}
  context "cell instance" do
    subject { cell(:notes) }

    it 'should respond to index' do
      # Given the new API which does not set the context to the cell itself
      # but rather to a wrapper with a method_missing definition that
      # delegates to the cell, which is a private instance variable thereof,
      # this is the only way I could reasonably test that the cell does
      # in fact implement the method in question. It will still raise an
      # ArgumentError, but if the method were entirely absent it would
      # raise a NoMethodError, and so we check for the exclusion of that
      # particular exception
      expect { index }.not_to raise_error NoMethodError
    end
  end

  context "cell rendering" do
    context "rendering index" do
      subject { render_cell(:notes, :index, current_user: regular_user, notes_target: sanctioning_request) }

      it { should have_selector("div.mygrid") }
      it { should have_selector("div[ng-init]") }
    end
  end

end
