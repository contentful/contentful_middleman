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
            :description=>"nice picture",
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
              :title=>"Doge",
              :description=>"nice picture",
              :url=>"//images.contentful.com/cfexampleapi/1x0xpXu4pSGS4OukSyWGUK/cc1239c6385428ef26f4180190532818/doge.jpg"
            }
          },
          :description=>{
            :'en-US'=>"such json\nwow"
          }
        }

        subject.map(context, entries_localized.first)

        expect(context.hashize).to eq(expected)
      end

      it 'maps entries with multiple locales with nested resources' do
        vcr('entries/localized_references') {
          subject = described_class.new entries, OptionsDouble.new(cda_query: {locale: '*'})
          expect(context.hashize).to eq({})

          expected = {
            :id=>"42kEjzNj9mIci2eyGOISiQ",
            :image=>{
              :'en-US'=>{
                title: "image-view-1139205 960 720",
                description: nil,
                url: "//images.contentful.com/1sjfpsn7l90g/6Rloj9MIxOwg0w2kqCaWS2/464b740a98d711905545f77d56fa3b2b/image-view-1139205_960_720.jpg"
              },
              :es=>{
                title: "background-image-967820 960 720",
                description: nil,
                url: "//images.contentful.com/1sjfpsn7l90g/2WGPppy4laAWWgUiWG02SA/3951271109e19ae45b21bb044b24b3ec/background-image-967820_960_720.jpg"
              },
              :zh=>{
                title: "image-view-1139204 960 720",
                description: nil,
                url: "//images.contentful.com/1sjfpsn7l90g/6zkhmrCizKuQUG0UmYKe4W/a8f90059b5bfd620791814f2c3edfaa4/image-view-1139204_960_720.jpg"
              }
            }
          }

          client = Contentful::Client.new(
            space: '1sjfpsn7l90g',
            access_token: 'e451a3cdfced9000220be41ed9c899866e8d52aa430eaf7c35b09df8fc6326f9',
            dynamic_entries: :auto
          )

          entries = client.entries(locale: '*')

          subject.map(context, entries.first)

          expect(context.hashize).to eq(expected)
        }
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

    it 'should not fail on missing asset file - #85' do
      vcr('entries/nil_file') {
        context = ContentfulMiddleman::Context.new
        client = Contentful::Client.new(
          space: '7f19o1co4hn7',
          access_token: '<ACCESS_TOKEN>',
          api_url: 'preview.contentful.com',
          dynamic_entries: :auto
        )

        entry_with_nil_file = client.entries('sys.id' => '6C4T3KAZUWaysA6ooQOWiE').first

        expect(entry_with_nil_file.one_media.file).to be_nil

        expect { subject.map(context, entry_with_nil_file) }.not_to raise_error
        expect(context.hashize[:oneMedia].keys.map(&:to_s)).not_to include('url')
      }
    end
  end
end
