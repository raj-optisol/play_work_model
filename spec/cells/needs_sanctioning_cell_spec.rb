# encoding: UTF-8
require 'spec_helper'

describe NeedsSanctioningCell do

  context 'cell instance' do
    subject { cell(:needs_sanctioning) }

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

  context 'cell rendering' do
    let(:club) { create_club }
    context 'rendering show' do
      subject { render_cell(:needs_sanctioning, :show, organization: club) }
      let(:club) { create_club }
      it { should have_selector('ul.disc') }

      context 'when the org is sanctioned' do
        before do
          club.stub(:sanctioned?) { true }
        end

        it { should have_selector('div.panel header a', text: /Request Cards/) }
        it { should have_selector('div.panel header a', text: /Print Cards/) }
        it { should have_selector('div.panel header a', text: /View previous/) }
      end
      context 'when the org is not sanctioned' do

        it { should_not have_selector('ul.disc li a', text: /Request Cards/) }
        it { should_not have_selector('ul.disc li a', text: /Print Cards/) }
        it { should_not have_selector('ul.disc li a', text: /View previous/) }
        it { should have_selector('ul.disc li', text: /Request Cards/) }
        it { should have_selector('ul.disc li', text: /Print Cards/) }
        it { should have_selector('ul.disc li', text: /View previous/) }
      end
    end
  end

end
