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

  let(:entries_localized) do
    vcr('mappers/entries_localized') {
      client = Contentful::Client.new(
        access_token: 'b4c0n73n7fu1',
        space: 'cfexampleapi',
        dynamic_entries: :auto
      )

      client.entries(locale: '*', include: 1)
    }
  end

  let(:options) { OptionsDouble.new }
  subject { described_class.new entries, options }

  describe 'instance methods' do
    let(:context) { ContentfulMiddleman::Context.new }

    describe '#map' do
      it 'maps entries without multiple locales' do
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

      it 'maps entries with multiple locales' do
        subject = described_class.new entries, OptionsDouble.new(cda_query: {locale: '*'})
        expect(context.hashize).to eq({})

        expected = {
          :id=>"6KntaYXaHSyIw8M6eo26OK",
          :name=> {
            :'en-US'=>"Doge"
          },
          :image=>{
            :'en-US'=>{
              "sys"=>{
                "type"=>"Link",
                "linkType"=>"Asset",
                "id"=>"1x0xpXu4pSGS4OukSyWGUK"
              }
            }
          },
          :description=>{
            :'en-US'=>"such json\nwow"
          }
        }

        subject.map(context, entries_localized.first)

        expect(context.hashize).to eq(expected)
      end
    end
  end

  describe 'attributes' do
    it ':entries' do
      expect(subject.entries).to match(entries)
    end
  end

  describe 'issues' do
    it 'should not fail on empty entry - #76' do
      entry = EntryDouble.new('foo', {}, nil)
      context = ContentfulMiddleman::Context.new

      expect { subject.map(context, entry) }.not_to raise_error
      expect(context.hashize).to eq(id: 'foo')
    end
  end
end
