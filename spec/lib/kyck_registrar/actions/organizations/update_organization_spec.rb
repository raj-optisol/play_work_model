# encoding: UTF-8
require 'spec_helper'

module KyckRegistrar
  module Actions
    describe UpdateOrganization do
      let(:org) { create_club }
      let(:requestor) { regular_user }
      subject { described_class.new(requestor, org) }

      describe '#initialize' do
        it 'takes a requestor and an organization' do
          expect { subject }.to_not raise_error
        end
      end

      describe '#execute' do
        before(:each) do
          manage_org = PermissionSet::MANAGE_ORGANIZATION
          create_location_for_locatable(org)
          add_user_to_org(requestor,
                          org,
                          title: 'Regular',
                          permission_sets: [manage_org])
        end

        context 'when the requestor has the required permissions' do
          let(:params) do
            { name: 'New Name',
              url: 'http://url.org',
              address1: '123 Main St',
              phone_number: '704-555-4444' }.with_indifferent_access
          end

          it 'updates the organization' do
            result = subject.execute(params)
            assert_equal result.name, 'New Name'
            assert_equal result.url, 'http://url.org'
            assert_equal result.locations.first.address1, '123 Main St'
            assert_equal result.phone_number.should, '704-555-4444'
          end

          it 'broadcasts the updated organization and attributes' do
            listener = double('listener')
            listener.should_receive(:organization_updated).with(
              instance_of(Organization),
              instance_of(ActiveSupport::HashWithIndifferentAccess), params)
            subject.subscribe(listener)

            subject.execute(params)
          end
        end

        context 'when the supplied params make organization invalid' do
          let(:input) do
            {
              name: ''
            }.with_indifferent_access
          end

          it 'broadcasts the invalid org' do
            listener = double('listener')
            listener.should_receive(:invalid_organization).with instance_of(
              Organization
            )
            subject.subscribe(listener)
            subject.execute(input)
          end

        end
      end
    end
  end
end
