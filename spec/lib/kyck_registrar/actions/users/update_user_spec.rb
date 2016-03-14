require 'spec_helper'

module KyckRegistrar
  module Actions
    describe UpdateUser do
      let(:repository){ UserRepository}
      let(:requestor) {regular_user(claimed: true) }
      let(:api) do
        d = double("KyckApi::V1::Account")
        d.stub('save_existing')
        d
      end

      let(:attributes) {
        {first_name: 'Barney', last_name: 'Rubble', birthdate: '01/07/2000'}
      }

      describe '#execute' do

        context 'when the requestor is the user to update' do
          subject do
            described_class.new(requestor)
          end

          it 'updates the user attributes' do
            user = subject.execute(attributes)
            user.first_name.should == 'Barney'
            user.last_name.should == 'Rubble'
            user.birthdate.should == Date.parse('07/01/2000')
          end

          it 'broadcasts the updated organization' do
            listener = double('listener')
            listener.should_receive(:user_updated).with(instance_of(  User ))
            subject.subscribe(listener)

            subject.execute(attributes)
          end

          context 'when email is supplied' do
            before do
              attributes[:email] = 'CAPITAL@EMAIL.COM'
              subject.kyck_api = api
              @obj = OpenStruct.new
              @obj.email=requestor.email
              requestor.stub(:authentication_account) {@obj}
            end

            it 'downcases the email' do
              user = subject.execute(attributes)
              user.email.should == 'capital@email.com'
            end

            it 'sends an update notification email' do
              mail_count = ActionMailer::Base.deliveries.count
              subject.execute(attributes.merge(:email => 'test@testaccount.com'))
              ActionMailer::Base.deliveries.count.should eq(mail_count + 1)
            end

            context 'when the user has logged in' do
              before do
                requestor.claimed = true
                requestor._data.save
                @obj = OpenStruct.new
                @obj.email=requestor.email
                requestor.stub(:authentication_account) {@obj}
              end
              it 'propagates the email change to the Accounts table' do
                user = subject.execute(attributes)
                user.authentication_account.email.should == 'capital@email.com'
              end
            end
          end

          context 'when the birthdate is an empty string' do

            it 'is ok' do
              attributes[:birthdate] = ''
              user = subject.execute(attributes)
              user.birthdate.should be_nil

            end
          end

          context 'when the supplied attributes make the user invalid' do
            let(:attributes) {
              {email: '', last_name: 'Rubble' }
            }

            it 'should broadcast an error' do
              listener = double('listener')
              listener.should_receive(:invalid_user).with instance_of User
              subject.subscribe(listener)

              subject.execute(attributes)
            end

          end

          context 'when the requestor is in an org with the user' do
            let(:club) {create_club}
            let(:player) {create_player_for_organization(club)}

            subject do
              d = described_class.new(requestor, player.user)
              api.stub(:save_existing).with(any_args)
              d.kyck_api = api
              d
            end

            before do
              add_user_to_org(requestor, club, permission_sets:[PermissionSet::MANAGE_PLAYER])
            end

            context 'and has the rights to manage players' do

              it 'updates the user attributes' do
                user = subject.execute(attributes)
                user.first_name.should == 'Barney'
                user.last_name.should == 'Rubble'
                user.birthdate.should == Date.parse('07/01/2000')
              end

              it 'should not send an update notification email' do
                mail_count = ActionMailer::Base.deliveries.count
                subject.execute(attributes.merge(:email => 'test@testaccount.com'))
                ActionMailer::Base.deliveries.count.should eq(mail_count)
              end
            end
          end
        end
      end
    end
  end
end
