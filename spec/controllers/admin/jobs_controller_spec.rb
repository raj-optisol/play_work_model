# encoding: UTF-8
require 'spec_helper'
module Admin
  describe JobsController do
    let(:normal_requestor) { regular_user }
    let(:admin_requestor) { admin_user }
    let(:kyck_requestor) { regular_user(email: 'someone@kyck.com') }
    let(:uscs_requestor) { regular_user(email: 'someone@usclubsoccer.org') }

    describe 'GET #fix_card_order' do
      subject { get(:fix_card_order) }

      context 'when user is a KYCK team member' do
        it do
          sign_in_user(uscs_requestor)
          expect(subject.status).to eq 200
        end
      end

      context 'when user is a USCS team member' do
        it do
          sign_in_user(kyck_requestor)
          expect(subject.status).to eq 200
        end
      end

      context 'when user is an admin' do
        it do
          sign_in_user(admin_requestor)
          expect { subject }.to raise_error KyckRegistrar::PermissionsError
        end
      end

      context 'when user is a regular user' do
        it do
          sign_in_user(normal_requestor)
          expect { subject }.to raise_error KyckRegistrar::PermissionsError
        end
      end
    end
  end
end
