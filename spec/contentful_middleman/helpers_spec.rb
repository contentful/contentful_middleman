require 'spec_helper'

class HelpersMock
  include ContentfulMiddleman::Helpers
end

class InstanceDouble
end

describe ContentfulMiddleman::Helpers do
  subject { HelpersMock.new }

  before(:each) do
    ContentfulMiddleman.instance_variable_set(:@contentful_middleman_instances, [])
  end


  describe 'instance methods' do
    describe '#contentful_instances' do
      it 'default - is an empty array' do
        expect(subject.contentful_instances).to eq([])
      end

      it 'returns multiple instances' do
        ContentfulMiddleman.instances << InstanceDouble.new
        ContentfulMiddleman.instances << InstanceDouble.new

        expect(subject.contentful_instances.size).to eq(2)
      end
    end
  end
end
