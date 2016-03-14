require 'spec_helper'
require 'kyck_file_store'

describe KyckFileStore do
  let(:local_options) { { path: '/tmp', store: :local } }
  let(:s3_options) do
    { path: 'tmp', store: :s3, bucket: 'theres-a-hole-in-the-bucket' }
  end
  let(:local_store)   { KyckFileStore.new(local_options) }
  let(:s3_store)      { KyckFileStore.new(s3_options)    }
  let(:stores) do
    { KyckFileStore::LocalFile => local_store,
      KyckFileStore::S3File    => s3_store }
  end

  describe '#read' do
    it 'calls .read on the file class' do
      stores.each do |klass, store|
        klass.should_receive(:read)
        store.read('somefile.txt')
      end
    end
  end

  describe '#write' do
    it 'calls .write on the file class' do
      stores.each do |klass, store|
        klass.should_receive(:write)
        store.write('paris_texas.txt', 'Tater Salad')
      end
    end
  end

  describe '#get_string_io' do
    it 'calls .get_string_io on the file class' do
      stores.each do |klass, store|
        klass.should_receive(:get_string_io)
        store.get_string_io('somefile.txt')
      end
    end
  end
end
