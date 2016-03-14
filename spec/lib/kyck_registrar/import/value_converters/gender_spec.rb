# encoding: UTF-8
require 'spec_helper'

module KyckRegistrar
  module Import
    module ValueConverters
      describe Gender do
        describe '#convert' do
          subject { described_class.convert(input_value) }

          context 'when passed a nil value' do
            let(:input_value) { nil }
            it 'returns nil' do
              assert_nil subject
            end
          end

          context 'when passed nonsense' do
            let(:input_value) { 'sadfaasd' }
            it 'returns nil' do
              assert_nil subject
            end
          end

          %w(M male Male m).each do |bad_value|
            context "when the value is #{bad_value}" do
              let(:input_value) { bad_value }
              it "returns 'male'" do
                assert_equal subject, 'male'
              end
            end
          end

          %w(F female Female f).each do |bad_value|
            context "when the value is #{bad_value}" do
              let(:input_value) { bad_value }
              it "returns 'female'" do
                assert_equal subject, 'female'
              end
            end
          end
        end
      end
    end
  end
end
