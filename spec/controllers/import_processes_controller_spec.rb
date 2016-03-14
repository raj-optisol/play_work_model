require 'spec_helper'
require 'fileutils'

describe ImportProcessesController do
  include Devise::TestHelpers

  let(:requestor) {regular_user}
  let(:club) {create_club}
  let(:csv) { Rack::Test::UploadedFile.new("#{Rails.root}/spec/support/import_players.csv")}
  before do
    sign_in_user(requestor)
  end

  after do
    FileUtils.rm_rf(Rails.root.join('public', 'imports', '*'))
  end

  describe '#create' do
    context 'when the requestor has MANAGE_ORGANIZATION for the club' do
      let(:params) do
        { organization_id: club.kyck_id, import_process:  { file: csv } }
      end

      let(:processor) { double('processor') }

      before do
        add_user_to_org(requestor, club, permission_sets: [PermissionSet::MANAGE_ORGANIZATION])
        processor.stub(:status=)
        processor.stub(:file_suffix)
        processor.stub(:save!)
        processor.stub(:execute)
        subject.processor = processor
      end

      it 'writes the file' do
        KyckFileStore.any_instance.should_receive(:write)
        request.env['CONTENT_TYPE'] = 'multipart/form-data'
        post :create, params
      end

      it 'queues up the import' do
        KyckFileStore.any_instance.stub(:write)
        processor.should_receive(:execute)
        post :create, params
      end
    end

    context 'when the requestor does not have the right privileges' do
      it 'redirects to root' do
        post :create, organization_id: club.kyck_id, import_process: {file: csv}
        response.should redirect_to root_path
      end

      it 'has a flash message saying user is not allowed' do
        post :create, organization_id: club.kyck_id, import_process: {file: csv}
        flash[:error].should =~ /have permissions/i
      end
    end
  end
end
