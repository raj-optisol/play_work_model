# encoding: UTF-8
require 'spec_helper'

describe ReportUSSFGenerator do
  subject(:generator) { described_class.new }

  describe '#csv_row' do
    it 'should call to generate row based on order data' do
      CSV::Row.stub(:new)
      generator.stub(:normalize)

      expect(generator).to receive(:normalize)
      generator.csv_row(nil)
    end
  end
end
