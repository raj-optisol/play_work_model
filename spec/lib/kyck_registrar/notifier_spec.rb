require_relative '../../../lib/kyck_registrar'
require 'logger'

module KyckRegistrar
  describe Notifier do
  
    subject {KyckRegistrar::Notifier.new}
    before(:each) do 
      KyckRegistrar.logger = Logger.new('/dev/null')
    end
    describe "#staff_added" do


      let(:to) {{email: 'fred@fred.com', name: 'Fred Flintstone'}}
      let(:from) {{email: 'wilma@fred.com', name: 'Wilma Flintstone'}}

      it "should take to and from params" do
        subject.staff_added("A Team", to, from)
      end

      it "should allow the mailer to be overridden" do
        mailer = Object.new
        mailer.stub(:staff_added!)
        subject.mailer = mailer
        subject.staff_added("A Team", to, from)
      end

      it "should call delegate the send call to the mailer " do
        mailer = Object.new
        mailer.should_receive(:staff_added!)
        subject.mailer = mailer
        subject.staff_added("A Team", to, from)
      end

    end

    describe "#staff_card_created" do
      let(:to) {{email: 'fred@fred.com', name: 'Fred Flintstone'}}
      let(:from) {{email: 'wilma@fred.com', name: 'Wilma Flintstone'}}

      it "should call delegate the send call to the mailer " do
        mailer = Object.new
        mailer.should_receive(:staff_card_created!)
        subject.mailer = mailer
        subject.staff_card_created("An org", to, from)
      end


    end
  end
end
