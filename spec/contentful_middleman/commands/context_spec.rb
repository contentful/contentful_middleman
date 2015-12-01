require 'spec_helper'

describe ContentfulMiddleman::Context do
  describe 'instance methods' do
    it '#set' do
      subject.set('foo', 'bar')
      expect(subject.foo).to eq 'bar'
    end

    it '#get' do
      subject.set('foo', 'bar')
      expect(subject.get('foo')).to eq 'bar'
    end

    describe '#method_missing' do
      it 'when :something= is called it uses #set(something, value)' do
        subject.foo = 'bar'
        expect(subject.foo).to eq 'bar'
      end
    end
  end
end
