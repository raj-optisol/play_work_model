require 'spec_helper'

describe DocumentHandler do
 
  describe "#delete" do

    let(:doc) {OpenStruct.new(file_name: 'test123')}
    let(:api) {OpenStruct.new}
    subject {described_class.new}

    it "calls the api" do
      subject.api = api
      api.should_receive(:destroy) 
      subject.delete("1234")
    end

    context "when the file is our default" do
    it "does not call the api" do
      subject.api = api
      api.should_not_receive(:destroy) 
      subject.delete("Doc-on-file_vopprg")
    end
    it "does not call the api" do
      subject.api = api
      api.should_not_receive(:destroy) 
      subject.delete("Background-check-passed")
    end
      
    
    end
  end
end
