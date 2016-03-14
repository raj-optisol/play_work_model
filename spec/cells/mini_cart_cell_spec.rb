require 'spec_helper'

describe MiniCartCell do

  context "cell instance" do
    subject { cell(:mini_cart) }

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
    let(:initiator) {regular_user}
    let(:payee) { create_sanctioning_body}
    let(:payer) { create_club}
    let!(:order) { create_order(initiator, payer, payee )}

    before do
      payer.stub(:sanctioned?) {true}
    end

    context "rendering show" do
      subject { render_cell(:mini_cart, :show, organization: payer, current_user: initiator) }

      it { should have_selector("a") }

    end
  end

end
