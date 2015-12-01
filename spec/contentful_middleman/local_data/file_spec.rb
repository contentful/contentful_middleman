require 'spec_helper'

class ThorDouble
  def create_file(path, *args, &block)
  end
end

describe ContentfulMiddleman::LocalData::File do
  describe 'class methods' do
    it '::thor= / ::thor' do
      expect(described_class.thor).to eq nil

      described_class.thor = 'foo'

      expect(described_class.thor).to eq 'foo'
    end
  end

  describe 'instance methods' do
    let(:thor) { ThorDouble.new }
    subject { described_class.new 'foo', 'bar' }

    before do
      ContentfulMiddleman::LocalData::Store.base_path = 'foo'
      described_class.thor = thor
    end

    it '#write' do
      expect(thor).to receive(:create_file).with(::File.join('foo', 'bar.yaml'), nil, {})

      subject.write
    end
  end
end
