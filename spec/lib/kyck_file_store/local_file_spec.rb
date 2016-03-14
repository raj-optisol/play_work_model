require 'spec_helper'
require 'kyck_file_store/local_file'

describe KyckFileStore::LocalFile do

  subject(:klass) { KyckFileStore::LocalFile }
  let(:file)      { 'somefile.txt'           }
  let(:content)   { 'Han shot first'         }

  before { klass.stub(:ensure_directory_exists) }

  describe '.read' do
    it 'reads in a file' do
      File.should_receive(:read).with(file)
      klass.read file
    end
  end

  describe '.write' do
    it 'writes out a file' do
      File.should_receive(:open).with(file, 'wb')
      klass.write(file, content)
    end

    it 'writes the content to the file' do
      another_file = double(file)
      another_file.stub(:write)
      File.should_receive(:open).with(file, 'wb').and_yield(another_file)
      another_file.should_receive(:write).with(content)
      klass.write(file, content)
    end
  end

  describe '.get_string_io' do
    before { klass.stub(:read).and_return(content) }

    it 'wraps the string in an object that responds to :readline' do
      klass.get_string_io(file).should respond_to :readline
    end

    it 'returns the string when :readline is called' do
      klass.get_string_io(file).readline.should eq content
    end
  end
end
