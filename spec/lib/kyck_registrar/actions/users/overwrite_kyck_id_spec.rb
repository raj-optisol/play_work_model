require 'spec_helper'

module KyckRegistrar
  module Actions
    describe OverwriteKyckID do
      let(:new_kyck_id) { SecureRandom.uuid }
      let(:user) { regular_user }

      context 'when called from the login process' do
        before do
          RSpec::Mocks.proxy_for(Oriented.graph).reset
        end

        after do
          RSpec::Mocks.proxy_for(Oriented.graph).reset
        end

        subject do
          action = described_class.new('_login_', user.kyck_id)
          action.execute(kyck_id: new_kyck_id)
        end

        it 'writes the new kyck id to the user' do
          subject.kyck_id.should == new_kyck_id
        end

        context 'when the user has logged in' do
          let!(:account) do
            create_account(
              kyck_id: user.kyck_id,
              email: user.email
            )
          end

          it 'writes the new kyck id to the authentication account' do
            subject
            account.reload
            account.kyck_id.to_s.should == new_kyck_id
          end
        end

        context 'when the user has orders' do
          let!(:order) { create_order(user, user, user) }

          it 'updates those orders with the new kyck_id' do
            subject
            order._data.reload
            order.initiator_id.to_s.should == new_kyck_id
          end
        end

        context 'when the user has order items' do
          let(:order) { create_order(user, user, user) }
          let(:order_item_attributes) do
            {
              product_for_obj_id: user.kyck_id,
              product_for_obj_type: 'User',
              amount: 25.0,
              product_id: '1234',
              product_type: 'CardProduct'
            }
          end
          let!(:order_item) do
            oi = order.add_order_item(order_item_attributes)
            OrderRepository.persist(order)
            oi
          end

          it 'updates those orders with the new kyck_id' do
            subject
            order_item._data.reload
            order_item.product_for_obj_id.to_s.should == new_kyck_id
          end
        end

        context 'when the user has import processes' do
          let!(:import) do
            ImportProcess.create(
              user_id: user.kyck_id,
              organization_id: '12345',
              file_name: 'a file'
            )
          end

          it 'updates those orders with the new kyck_id' do
            subject
            import.reload
            import.user_id.to_s.should == new_kyck_id
          end
        end

        context 'when the user has payment_methods' do
          let!(:payment_method) do
            p = PaymentMethod.build(payment_method_attributes)
            PaymentMethodRepository.persist!(p)
            p
          end
          let(:payment_method_attributes) do
            {
              user_id: user.kyck_id,
              kind: :amex
            }
          end

          it 'updates those orders with the new kyck_id' do
            subject
            payment_method._data.reload
            payment_method.user_id.to_s.should == new_kyck_id
          end
        end

        context 'when the user has user_settings' do
          let!(:user_settings) do
            us = UserSettings.build(user_id: user.kyck_id)
            UserSettingsRepository.persist(us)
          end

          it 'updates those orders with the new kyck_id' do
            subject
            user_settings._data.reload
            user_settings.user_id.to_s.should == new_kyck_id
          end
        end
      end


      context 'when commit is desired' do

        it 'commits Orientdb' do
          Oriented.graph.should_receive(:commit).at_least(:once)
          action = described_class.new('_login_', user.kyck_id)
          action.execute(kyck_id: new_kyck_id, commit: true)
        end
      end

      context 'when an error occurs' do
        subject { described_class.new('_login_', user.kyck_id) }
        before do
          subject.stub(:update_user).and_raise StandardError
        end
        let!(:payment_method) do
          p = PaymentMethod.build(payment_method_attributes)
          PaymentMethodRepository.persist!(p)
          p
        end

        let(:payment_method_attributes) do
          {
            user_id: user.kyck_id,
            kind: :amex
          }
        end

        it 'rollsback Orientdb' do
          Oriented.graph.should_receive(:rollback)
          subject.execute(kyck_id: new_kyck_id)
        end

        it 'does not change the payment method kyck id' do
          subject.execute(kyck_id: new_kyck_id)
          pms = PaymentMethodRepository.find_by_attrs(user_id: user.kyck_id)
          pms.should_not be_empty
        end
      end
    end
  end
end
