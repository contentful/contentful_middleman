require 'spec_helper'

describe ContentfulMiddleman::VersionHash do
  let(:path) { File.expand_path(File.join(File.dirname(__FILE__), '..', 'fixtures', 'space_hash_fixtures')) }
  describe 'class methods' do
    it '::source_root=' do
      described_class.source_root = 'foobar'
      expect(described_class.instance_variable_get(:@source_root)).to eq('foobar')
    end

    describe '::read_for_space' do
      before do
        described_class.source_root = path
      end

      it 'unhashed space returns nil' do
        expect(described_class.read_for_space('i_dont_exist')).to eq(nil)
      end

      it 'hashed space returns hash' do
        expect(described_class.read_for_space('foo').chomp).to eq('bar')
      end
    end

    describe '::write_for_space_with_entries' do
      let(:entries) { [EntryDouble.new(1, {}, {}, '2015-11-25'), EntryDouble.new(2, {}, {}, '2015-11-25')] }

      before do
        described_class.source_root = path
      end

      it 'hashes entries and saves them on a file' do
        allow(::File).to receive(:open).with(File.join(path, '.my_space-space-hash'), 'w')
        expect(Digest::SHA1).to receive(:hexdigest)

        described_class.write_for_space_with_entries('my_space', entries)
      end

      it 'matches hash on next read' do
        sorted_entries = entries.sort { |a, b| a.id <=> b.id }
        hash = Digest::SHA1.hexdigest(sorted_entries.map { |e| "#{e.id}#{e.updated_at}" }.join)

        described_class.write_for_space_with_entries('my_space', entries)

        expect(described_class.read_for_space('my_space')).to eq(hash)
      end
    end
  end
end
