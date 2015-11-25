require 'spec_helper'

class ClientDouble
  def entries
    []
  end
end

describe ContentfulMiddleman::ImportTask do
  let(:path) { File.expand_path(File.join(File.dirname(__FILE__), '..', 'fixtures', 'space_hash_fixtures')) }
  subject { described_class.new 'foobar', {}, {}, ClientDouble.new }

  describe 'instance methods' do
    before do
        ContentfulMiddleman::VersionHash.source_root = path
    end

    describe '#run' do
      it 'doesnt change when data did not change' do
        expect_any_instance_of(ContentfulMiddleman::LocalData::Store).to receive(:write)

        subject.run
        expect(subject.changed_local_data?).to eq(false)
      end

      it 'changes when data is new' do
        subject = described_class.new 'blah', {}, {}, ClientDouble.new

        if ::File.exist?(::File.join(path, '.blah-space-hash'))
          ::File.delete(::File.join(path, '.blah-space-hash'))
        end

        expect_any_instance_of(ContentfulMiddleman::LocalData::Store).to receive(:write)

        subject.run

        expect(subject.changed_local_data?).to eq(true)
      end
    end
  end
end
