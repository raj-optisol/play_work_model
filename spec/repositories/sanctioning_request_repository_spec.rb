require 'spec_helper'

describe SanctioningRequestRepository do
  describe "#get_pending_request" do
    let(:org) { create_club }
    let(:sb) { create_sanctioning_body }
    let(:issuer) { regular_user }
    let(:req) { create_sanctioning_request(sb, org, issuer) }

    context "when request are pending" do
      it "returns the pending request" do
        req
        res = SanctioningRequestRepository.get_pending_request(org)
        res.should_not be_nil
        res.should be_a(SanctioningRequest)
      end
    end

    context "when request are not pending" do
      it "returns empty" do
        req.status=:denied
        SanctioningRequestRepository.persist req
        res = SanctioningRequestRepository.get_pending_request(org)
        res.should be_nil
      end
    end
  end

  describe "#denied_within_time" do
    let(:org) { create_club }
    let(:sb) { create_sanctioning_body }
    let(:issuer) { regular_user }
    let(:req) { create_sanctioning_request(sb, org, issuer, {status: :denied }) }

    context "when request has been denied recently" do
      it "returns true" do
        SanctioningRequestRepository.persist req
        Timecop.freeze(Date.today + 15) do
          SanctioningRequestRepository.denied_within_time(org).should_not be_empty
        end
      end
    end

    context "when request has not been denied recently" do

      it "returns false" do
        Timecop.freeze(Date.today + 40) do
          SanctioningRequestRepository.denied_within_time(org).should be_empty
        end
      end
    end
  end
end
