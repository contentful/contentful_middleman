require 'spec_helper'

class ExtensionDouble
  attr_reader :options
  def initialize(options = OptionsDouble.new)
    @options = options
  end
end

class MapperDouble
end

describe ContentfulMiddleman::Instance do
  let(:extension) { ExtensionDouble.new }
  let(:options) { extension.options }
  subject { described_class.new(extension) }

  describe 'instance methods' do
    describe '#entries' do
      it 'gets entries from API' do
        vcr('instance/entries_1') {
          client = subject.send(:client)

          expect(client).to receive(:entries).with(options.cda_query)

          subject.entries
        }
      end

      it 'all_entries' do
        vcr('instance/entries_2') {
          allow(options).to receive(:all_entries) { true }
          client = subject.send(:client)

          expect(client).to receive(:entries).with(limit: 1).and_call_original
          expect(client).to receive(:entries).with(options.cda_query.merge(limit: 1000, skip: 0, order: 'sys.createdAt')).and_call_original

          subject.entries
        }
      end
    end

    it '#space_name' do
      expect(subject.space_name).to eq('cats')
    end

    describe '#content_types_ids_to_mappers' do
      it 'returns an empty hash if none set' do
        expect(subject.content_types_ids_to_mappers).to eq({})
      end

      it 'returns a hash of ct_id => mapper' do
        allow(options).to receive(:content_types) { {an_id: {mapper: MapperDouble}} }

        expect(subject.content_types_ids_to_mappers).to eq({an_id: MapperDouble})
      end
    end

    describe '#content_types_ids_to_names' do
      it 'returns an empty hash if none set' do
        expect(subject.content_types_ids_to_names).to eq({})
      end

      it 'returns a hash of ct_id => name' do
        allow(options).to receive(:content_types) { {an_id: {name: 'foo'}} }

        expect(subject.content_types_ids_to_names).to eq({an_id: 'foo'})
      end
    end
  end
end
