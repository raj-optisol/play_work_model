require 'spec_helper'
require 'kyck_file_store/s3_file'

describe KyckFileStore::S3File do
  subject(:klass)   { KyckFileStore::S3File }
  let(:file)        { 'somefile.txt'        }
  let(:content)     { 'Han shot first'      }
  let(:bucket_name) { 'kyck-the-bucket'     }

  before do
    @obj = double('obj')
    @obj.stub(:read) { content }
    @obj.stub(:write)
    AWS::S3::ObjectCollection.any_instance.stub(:[]) { @obj }
  end

  context 'very hacky sanity checks' do
    it 'gets the right bucket' do
      klass.read(file, bucket_name)
      klass.instance_variable_get(:@bucket).name.should eq bucket_name
    end
  end

  describe '.read' do
    it 'reads in a file' do
      @obj.should_receive(:read)
      klass.read(file, bucket_name)
    end
  end

  describe '.write' do
    it 'writes the content to the s3 object' do
      @obj.should_receive(:write).with(content)
      klass.write(file, content, bucket_name)
    end
  end

  describe '.get_string_io' do
    before { klass.stub(:read).and_return(content) }

    it 'wraps the string in an object that responds to :readline' do
      klass.get_string_io(file, bucket_name).should respond_to :readline
    end

    it 'returns the string when :readline is called' do
      klass.get_string_io(file, bucket_name).readline.should eq content
    end
  end
end
