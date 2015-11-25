require 'spec_helper'

class FileDouble
  def write
  end
end

describe ContentfulMiddleman::LocalData::Store do
  let(:path) { File.expand_path(File.join(File.dirname(__FILE__), '..', '..', 'fixtures', 'backup_fixtures')) }

  before do
    described_class.base_path = nil
  end

  describe 'class methods' do
    it '::base_path / ::base_path=' do
      expect(described_class.base_path).to eq nil

      described_class.base_path = 'foo'

      expect(described_class.base_path).to eq 'foo'
    end
  end

  describe 'instance methods' do
    before do
      described_class.base_path = 'foo'
    end

    let(:file) { FileDouble.new }
    subject { described_class.new [file], path }

    describe '#write' do
      it 'writes with backup' do
        expect(subject).to receive(:do_with_backup)

        subject.write
      end

      it 'calls write on every file object' do
        expect(file).to receive(:write)

        subject.write
      end
    end
  end
end
