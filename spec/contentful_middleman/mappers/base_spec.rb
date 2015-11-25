require 'spec_helper'

describe ContentfulMiddleman::Mapper::Base do
  let(:entries) do
    vcr('mappers/entries') {
      client = Contentful::Client.new(
        access_token: 'b4c0n73n7fu1',
        space: 'cfexampleapi',
        dynamic_entries: :auto
      )

      client.entries
    }
  end
  subject { described_class.new entries }

  describe 'instance methods' do
    let(:context) { ContentfulMiddleman::Context.new }

    it '#map' do
      expect(context.hashize).to eq({})

      expected = {
        :id=>"6KntaYXaHSyIw8M6eo26OK",
        :name=>"Doge",
        :image=> {
          :title=>"Doge",
          :url=> "//images.contentful.com/cfexampleapi/1x0xpXu4pSGS4OukSyWGUK/cc1239c6385428ef26f4180190532818/doge.jpg"
        },
        :description=>"such json\nwow"
      }

      subject.map(context, entries.first)

      expect(context.hashize).to eq(expected)
    end
  end

  describe 'attributes' do
    it ':entries' do
      expect(subject.entries).to match(entries)
    end
  end
end
