require 'spec_helper'

describe SanctioningBodyLinkCell do

  context "cell instance" do
    subject { cell(:sanctioning_body_link) }

    it 'should respond to show' do
      # Given the new API which does not set the context to the cell itself
      # but rather to a wrapper with a method_missing definition that
      # delegates to the cell, which is a private instance variable thereof,
      # this is the only way I could reasonably test that the cell does
      # in fact implement the method in question. It will still raise an
      # ArgumentError, but if the method were entirely absent it would
      # raise a NoMethodError, and so we check for the exclusion of that
      # particular exception
      expect { show }.not_to raise_error NoMethodError
    end
  end

  context "cell rendering" do
    context "rendering show" do
      subject { render_cell(:sanctioning_body_link, :show) }

      context "when a sanctioning body exists" do
        before do
          SanctioningBodyRepository.stub(:all) {[create_sanctioning_body]}
        end
        it { should have_selector("a")}
      end
      context "when a sanctioning body does not exist" do
        it { should_not have_selector("a")}
      end
    end
  end

end
