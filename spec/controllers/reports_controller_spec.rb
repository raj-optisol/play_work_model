require 'spec_helper'

describe ReportsController do
  include Devise::TestHelpers

  let(:requestor) { regular_user }
  let(:uscs) { create_sanctioning_body(name: 'USCS') }

  before(:each) do
    sign_in_user(requestor) # TODO
  end

  describe '#overview' do
    context 'when an unauthorized user sends a request' do
      it 'raises a PermissionsError' do
        expect {
          get :overview, sanctioning_body_id: uscs.kyck_id
        } .to raise_error KyckRegistrar::PermissionsError
      end
    end

    context 'when an authorized user sends a request' do
      it 'displays the overview template' do
        add_user_to_org(
          requestor,
          uscs,
          permission_sets: [PermissionSet::RUN_FINANCIAL_REPORT]
        )

        get :overview, sanctioning_body_id: uscs.kyck_id
        response.should render_template :overview
      end
    end
  end

  describe '#player_registration_report' do
    context 'when an unauthorized user sends a request' do
      it 'raises a PermissionsError' do
        expect {
          get :player_registration_report, sanctioning_body_id: uscs.kyck_id
        } .to raise_error KyckRegistrar::PermissionsError
      end
    end

    context 'when an authorized user sends a request' do
      it 'displays the player_registration_report template' do
        add_user_to_org(
          requestor,
          uscs,
          permission_sets: [PermissionSet::RUN_FINANCIAL_REPORT]
        )

        get :player_registration_report, sanctioning_body_id: uscs.kyck_id
        response.should render_template :player_registration_report
      end
    end
  end

  describe '#staff_registration_report' do
    context 'when an unauthorized user sends a request' do
      it 'raises a PermissionsError' do
        expect {
          get :staff_registration_report, sanctioning_body_id: uscs.kyck_id
        } .to raise_error KyckRegistrar::PermissionsError
      end
    end

    context 'when an authorized user sends a request' do
      it 'displays the staff_registration_report template' do
        add_user_to_org(
          requestor,
          uscs,
          permission_sets: [PermissionSet::RUN_FINANCIAL_REPORT]
        )

        get :staff_registration_report, sanctioning_body_id: uscs.kyck_id
        response.should render_template :staff_registration_report
      end
    end
  end

  describe '#summary_registration_report' do
    context 'when an unauthorized user sends a request' do
      it 'raises a PermissionsError' do
        expect {
          get :summary_registration_report, sanctioning_body_id: uscs.kyck_id
        } .to raise_error KyckRegistrar::PermissionsError
      end
    end

    context 'when an authorized user sends a request' do
      it 'displays the summary_registration_report template' do
        add_user_to_org(
          requestor,
          uscs,
          permission_sets: [PermissionSet::RUN_FINANCIAL_REPORT]
        )

        get :summary_registration_report, sanctioning_body_id: uscs.kyck_id
        response.should render_template :summary_registration_report
      end
    end
  end

  describe '#ussf_report' do
    context 'when an unauthorized user sends a request' do
      it 'raises a PermissionsError' do
        expect {
          get :ussf_report, sanctioning_body_id: uscs.kyck_id
        } .to raise_error KyckRegistrar::PermissionsError
      end
    end

    context 'when an authorized user sends a request' do
      it 'displays the ussf_report template' do
        add_user_to_org(
          requestor,
          uscs,
          permission_sets: [PermissionSet::RUN_FINANCIAL_REPORT]
        )

        get :ussf_report, sanctioning_body_id: uscs.kyck_id
        response.should render_template :ussf_report
      end
    end
  end
end
