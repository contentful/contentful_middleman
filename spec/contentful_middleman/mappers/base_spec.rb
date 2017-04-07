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
          :_meta=> {
            :content_type_id=> 'dog',
            :updated_at=> '2013-11-18T09:13:37+00:00',
            :created_at=> '2013-11-06T09:45:27+00:00',
            :id=> '6KntaYXaHSyIw8M6eo26OK'
          },
          :name=>"Doge",
          :image=> {
            :_meta=> {
              :updated_at=> "2013-12-18T13:27:14+00:00",
              :created_at=> "2013-11-06T09:45:10+00:00",
              :id=> "1x0xpXu4pSGS4OukSyWGUK"
            },
            :title=>"Doge",
            :description=>"nice picture",
            :url=> "//images.contentful.com/cfexampleapi/1x0xpXu4pSGS4OukSyWGUK/cc1239c6385428ef26f4180190532818/doge.jpg"
          },
          :description=>"such json\nwow"
        }

        subject.map(context, entries.first)

        expect(context.hashize).to match(expected)
      end

      it 'maps entries with multiple locales' do
        subject = described_class.new entries, OptionsDouble.new(cda_query: {locale: '*'})
        expect(context.hashize).to eq({})

        expected = {
          :_meta => {
            :content_type_id=>"dog",
            :updated_at=>"2013-11-18T09:13:37+00:00",
            :created_at=>"2013-11-06T09:45:27+00:00",
            :id=>"6KntaYXaHSyIw8M6eo26OK"
          },
          :id=>"6KntaYXaHSyIw8M6eo26OK",
          :name=> {
            :'en-US'=>"Doge"
          },
          :image=> {
            :'en-US'=> {
              :_meta=> {
                :updated_at=> "2013-12-18T13:27:14+00:00",
                :created_at=> "2013-11-06T09:45:10+00:00",
                :id=>"1x0xpXu4pSGS4OukSyWGUK"
              },
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
            :_meta => {
              :content_type_id=>"test",
              :updated_at=>"2016-09-29T14:53:54+00:00",
              :created_at=>"2016-09-29T14:53:54+00:00",
              :id=>"42kEjzNj9mIci2eyGOISiQ"
            },
            :id=>"42kEjzNj9mIci2eyGOISiQ",
            :image=>{
              :'en-US'=> {
                :_meta=> {
                  :updated_at=> "2016-09-29T14:53:26+00:00",
                  :created_at=> "2016-09-29T14:53:26+00:00",
                  :id=> "6Rloj9MIxOwg0w2kqCaWS2"
                },
                title: "image-view-1139205 960 720",
                description: nil,
                url: "//images.contentful.com/1sjfpsn7l90g/6Rloj9MIxOwg0w2kqCaWS2/464b740a98d711905545f77d56fa3b2b/image-view-1139205_960_720.jpg"
              },
              :es=>{
                :_meta=> {
                  :updated_at=> "2016-09-29T14:53:26+00:00",
                  :created_at=> "2016-09-29T14:53:26+00:00",
                  :id=> "2WGPppy4laAWWgUiWG02SA"
                },
                title: "background-image-967820 960 720",
                description: nil,
                url: "//images.contentful.com/1sjfpsn7l90g/2WGPppy4laAWWgUiWG02SA/3951271109e19ae45b21bb044b24b3ec/background-image-967820_960_720.jpg"
              },
              :zh=> {
                :_meta=> {
                  :updated_at=> "2016-09-29T14:53:26+00:00",
                  :created_at=> "2016-09-29T14:53:26+00:00",
                  :id=>"6zkhmrCizKuQUG0UmYKe4W"
                },
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

      it 'maps entries with multiple locales with nested resources that are also localized' do
        vcr('entries/localized_references_localized_assets') {
          subject = described_class.new entries, OptionsDouble.new(cda_query: {locale: '*'})
          expect(context.hashize).to eq({})

          expected = {
            :_meta => {
              :content_type_id=>"test",
              :updated_at=>"2016-10-05T14:32:07+00:00",
              :created_at=>"2016-10-05T14:32:07+00:00",
              :id=>"2HjFERK39eeCYegCayUkMK"
            },
            id: "2HjFERK39eeCYegCayUkMK",
            image: {
              :"en-US" => {
                :_meta=> {
                  :updated_at=> "2016-10-05T14:31:36+00:00",
                  :created_at=> "2016-10-05T14:31:36+00:00",
                  :id=>"14bZJKTr6AoaGyeg4kYiWq"
                },
                title: "EN Title",
                description: "EN Description",
                url: "//assets.contentful.com/bht13amj0fva/14bZJKTr6AoaGyeg4kYiWq/13f00bdf75c1320061ce471a3881e831/Flag_of_the_United_States.svg"
              },
              es: {
                :_meta=> {
                  :updated_at=> "2016-10-05T14:31:36+00:00",
                  :created_at=> "2016-10-05T14:31:36+00:00",
                  :id=>"14bZJKTr6AoaGyeg4kYiWq"
                },
                title: "ES Title",
                description: "ES Description",
                url: "//assets.contentful.com/bht13amj0fva/14bZJKTr6AoaGyeg4kYiWq/5501c98c296af77b9acba1146ea3e211/Flag_of_Spain.svg"
              }
            }
          }

          client = Contentful::Client.new(
            space: 'bht13amj0fva',
            access_token: 'bb703a05e107148bed6ee246a9f6b3678c63fed7335632eb68fe1b689c801534',
            dynamic_entries: :auto
          )

          entry = client.entries(locale: '*').first

          subject.map(context, entry)

          expect(entry.image.id).to eq(entry.fields('es')[:image].id)
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
      expect(context.hashize).to eq({
        :_meta=> {
          :content_type_id=> 'foo_ct',
          :id=> 'foo'
        },
        id: 'foo'
      })
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
        expect(context.hashize[:one_media].keys.map(&:to_s)).not_to include('url')
      }
    end

    it 'should serialize repeated entries in an array - #99' do
      vcr('entries/repeated_entry') {
        context = ContentfulMiddleman::Context.new
        client = Contentful::Client.new(
          space: 'a80guayqr8ut',
          access_token: '8b915cca980970ee60f749bf4435a48c61c9482038f185d6d0c4325bbde87170',
          dynamic_entries: :auto
        )

        entry_with_repeated_item = client.entries('sys.id' => 'DT1yQgZABwuWeY842sGYY').first

        subject.map(context, entry_with_repeated_item)
        hash = YAML.load(context.to_yaml)
        expect(hash[:bars]).to match([
          {
            :id=>"1Xq3cu45qguO4Uiwc2yycY",
            :_meta=> {
              :content_type_id=>"bar",
              :updated_at=>"2016-12-12T13:40:58+00:00",
              :created_at=>"2016-12-12T13:40:58+00:00",
              :id=>"1Xq3cu45qguO4Uiwc2yycY"},
              :name=>"bar_1"
          },
          {
            :id=>"6jLRFVvafuM6E0QiCA8YMu",
             :_meta=> {
              :content_type_id=>"bar",
              :updated_at=>"2016-12-12T13:41:05+00:00",
              :created_at=>"2016-12-12T13:41:05+00:00",
              :id=>"6jLRFVvafuM6E0QiCA8YMu"
            },
            :name=>"bar_2"
          },
          {
            :id=>"1Xq3cu45qguO4Uiwc2yycY",
            :_meta=> {
              :content_type_id=>"bar",
              :updated_at=>"2016-12-12T13:40:58+00:00",
              :created_at=>"2016-12-12T13:40:58+00:00",
              :id=>"1Xq3cu45qguO4Uiwc2yycY"
            },
            :name=>"bar_1"
          }
        ])
        expect(hash[:bars].first).to eq(hash[:bars].last)
      }
    end
  end
end
