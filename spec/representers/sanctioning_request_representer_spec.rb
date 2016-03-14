require 'spec_helper'

describe SanctioningRequestRepresenter do

  let(:issuer) {regular_user}
  let(:org) { create_club }
  let(:doc) { regular_user}
  let(:registrar) { regular_user}
  let(:president) { regular_user}
  let(:sanctioning_body) {create_sanctioning_body}
  let(:sanc_request) {
    sr = SanctioningRequest.build(
      kyck_id: create_uuid,
      status: "new",
      status: :approved
    )

    sr.issuer =  issuer._data
    sr.target = sanctioning_body._data
    sr.on_behalf_of = org._data

    sr = SanctioningRequestRepository.persist sr

  }

  describe "#to_json" do

    subject{ j = sanc_request.extend(SanctioningRequestRepresenter).to_json(current_user: issuer)

             JSON.parse(j)
    }
    context "when all contacts are different" do
      before do
        add_user_to_org(doc, org, title: 'doc')
        add_user_to_org(registrar, org, title: 'registrar')
        add_user_to_org(president, org, title: 'president')
      end


      %w(kind status).each do |attr|
        it "include the #{attr}" do
          subject[attr].should == sanc_request.send(attr).to_s
        end
      end

      it "includes the organization's name" do
        org.name
        subject["name"].should == org.name
      end

      it "include the issuer" do
        subject["issuer"]["id"].should == issuer.kyck_id
      end

      it "include the doc" do
        subject["doc"]["id"].should == doc.kyck_id
      end

      it "include the registrar" do
        subject["registrar"]["id"].should == registrar.kyck_id
      end

      it "include the doc" do
        subject["president"]["id"].should == president.kyck_id
      end

      it "include the target" do
        subject["target"]["id"].should == sanctioning_body.kyck_id.to_s
      end

      it "include the on_behalf_of " do
        subject["on_behalf_of"]["id"].should == org.kyck_id.to_s
      end
    end
  end
end
