require 'spec_helper'

class CustomEntryRenderer < RichTextRenderer::BaseNodeRenderer
  def render(node)
    "<div>Custom Content</div>"
  end
end

class OtherCustomEntryRenderer < RichTextRenderer::BaseNodeRenderer
  def render(node)
    "<h1>#{node['data'].body}</h1>"
  end
end

class InstanceMock
  def initialize(mappings = {})
    @mappings = mappings
  end

  def options
    {
      rich_text_mappings: @mappings
    }
  end
end

class AppMock
  def initialize(instances = {})
    @instances = instances
  end

  def extensions
    {
      contentful: @instances
    }
  end
end

class HelpersMock
  include ContentfulMiddleman::Helpers

  def initialize(instances = {})
    @instances = instances
  end

  def app
    AppMock.new(@instances)
  end
end

class InstanceDouble
end

describe ContentfulMiddleman::Helpers do
  let(:entry) do
    {
      _meta: {
        id: 'foo'
      },
      value_field: {
        'es' => 'foo',
        'en-US' => 'bar'
      },
      array_field: [
        {
          'es' => 'foobar',
          'en-US' => 'baz'
        }
      ],
      nested_array: {
        'en-US' => [
          {
            id: 'foo',
            _meta: {
              id: 'foo'
            },
            name: {
              'es' => 'foo',
              'en-US' => 'bar'
            }
          }, {
            id: 'foo',
            _meta: {
              id: 'foo'
            },
            name: {
              'en-NZ' => 'bar',
              'en-US' => 'foo'
            },
          }
        ]
      },
      nested_hash: {
        'en-US' => {
          id: 'foo',
          _meta: {
            id: 'foo'
          },
          name: {
            'es' => 'foo',
            'en-US' => 'bar'
          }
        }
      }
    }
  end

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

    describe 'localization helpers' do
      describe '#localize_value' do
        it 'returns value if not a hash independently of locale' do
          expect(subject.localize_value('foo', 'es')).to eq('foo')
        end

        describe 'value is a hash' do
          it 'returns fallback_locale value if locale not found' do
            expect(subject.localize_value({'en-US' => 'foo'}, 'es')).to eq('foo')
            expect(subject.localize_value({'de-DE' => 'bar'}, 'es', 'de-DE')).to eq('bar')
          end

          it 'returns localized value if locale found' do
            expect(subject.localize_value({'es' => 'foobar'}, 'es')).to eq('foobar')
          end

          it 'returns original values if both locale and fallback_locale not found' do
            expect(subject.localize_value({'foo' => 'baz'}, 'es', 'de-DE')).to eq({'foo'=>'baz'})
          end
        end
      end

      describe '#localize_array' do
        it 'calls #localize_value for every element in the array' do
          expect(subject).to receive(:localize_value).with({'es' => 'foo'}, 'es', 'en-US')

          subject.localize_array([{'es' => 'foo'}], 'es')
        end
      end

      describe '#localize' do
        it 'calls #localize_value for a value field' do
          expect(subject).to receive(:localize_value).with({'es' => 'foo', 'en-US' => 'bar'}, 'es', 'en-US').and_call_original

          expect(subject.localize(entry, :value_field, 'es')).to eq('foo')
        end

        it 'calls #localize_array for an array field' do
          expect(subject).to receive(:localize_array).with([{'es' => 'foobar', 'en-US' => 'baz'}], 'es', 'en-US').and_call_original

          expect(subject.localize(entry, :array_field, 'es')).to eq(['foobar'])
        end
      end

      it '#localize_entry' do
        localized_entry = subject.localize_entry(entry, 'es')
        expect(localized_entry).to eq({
          '_meta' => { 'id' => 'foo' },
          'value_field' => 'foo',
          'array_field' => ['foobar'],
          'nested_array' => [
            {
              'id' => 'foo',
              '_meta' => {
                'id' => 'foo'
              },
              'name' => 'foo'
            }, {
              'id' => 'foo',
              '_meta' => {
                'id' => 'foo'
              },
              'name' => 'foo'
            }
          ],
          'nested_hash' => {
            'id' => 'foo',
            '_meta' => {
              'id' => 'foo'
            },
            'name' => 'foo'
          }
        })

        expect(localized_entry[:_meta]).to eq({ 'id' => 'foo' })
        expect(localized_entry[:nested_array][0][:id]).to eq('foo')
        expect(localized_entry[:nested_hash][:id]).to eq('foo')
      end
    end

    describe 'preview helpers' do
      describe '#with_preview' do
        it 'creates a preview client' do
          vcr('helpers/preview') {
            subject.with_preview(space: 'cfexampleapi', access_token: 'b4c0n73n7fu1') do |preview|
              expect(preview).to be_a ::Contentful::Client
              expect(preview).to be_a ::ContentfulMiddleman::Tools::PreviewProxy

              preview_entries = preview.entries
              expect(preview_entries.size).to eq 11
              expect(preview_entries).to be_a ::Contentful::Array
            end
          }
        end
      end
    end

    describe 'rich text helpers' do
      describe '#rich_text' do
        it 'renders a rich text field to HTML' do
          expected = [
            '<h1>Some heading</h1>',
            '<p></p>',
            '<div>{"target"=>{"sys"=>{"id"=>"49rofLvvxCOiIMIi6mk8ai", "type"=>"Link", "linkType"=>"Entry"}}}</div>',
            '<h2>Some subheading</h2>',
            '<p><b>Some bold</b></p>',
            '<p><i>Some italics</i></p>',
            '<p><u>Some underline</u></p>',
            '<p></p>',
            '<p></p>',
            '<div>{"target"=>{"sys"=>{"id"=>"5ZF9Q4K6iWSYIU2OUs0UaQ", "type"=>"Link", "linkType"=>"Entry"}}}</div>',
            '<p></p>',
            '<p>Some raw content</p>',
            '<p></p>',
            '<p>An unpublished embed:</p>',
            '<p></p>',
            '<div>{"target"=>{"sys"=>{"id"=>"q2hGXkd5tICym64AcgeKK", "type"=>"Link", "linkType"=>"Entry"}}}</div>',
            '<p>Some more content</p>'
          ].join("\n")

          expect(subject.rich_text(json('structured_text'))).to eq expected
        end

        it 'supports multiple configurations' do
          vcr('helpers/rich_text') {
            # Instances are a 0-based progressive hash with keys in the shape "instance_#{index}"
            instances = {
              "instance_0" => InstanceMock.new('embedded-entry-block' => CustomEntryRenderer),
              "instance_1" => InstanceMock.new('embedded-entry-block' => OtherCustomEntryRenderer)
            }
            subject = HelpersMock.new(instances)

            expected_default = [
              '<h1>Some heading</h1>',
              '<p></p>',
              '<div>Custom Content</div>',
              '<h2>Some subheading</h2>',
              '<p><b>Some bold</b></p>',
              '<p><i>Some italics</i></p>',
              '<p><u>Some underline</u></p>',
              '<p></p>',
              '<p></p>',
              '<div>Custom Content</div>',
              '<p></p>',
              '<p>Some raw content</p>',
              '<p></p>',
              '<p>An unpublished embed:</p>',
              '<p></p>',
              '<p>Some more content</p>',
              '<p><code>Some code</code></p>',
              '<p><a href="https://www.contentful.com">A hyperlink</a></p>',
              '<ul><li><p>Ul list</p></li><li><p>A few <b>items</b></p><ol><li><p>Ordered list nested inside an Unordered list item</p></li></ol></li></ul>',
              '<ol><li><p>Ol list</p></li><li><p>two</p></li><li><p>three</p></li></ol>',
              '<hr />',
              '<p></p>',
              '<blockqoute><p>An inspirational quote</p><p></p></blockqoute>',
              '<p></p>'
            ].join("\n")

            expected_different_config = [
              '<h1>Some heading</h1>',
              '<p></p>',
              '<h1>Embedded 1</h1>',
              '<h2>Some subheading</h2>',
              '<p><b>Some bold</b></p>',
              '<p><i>Some italics</i></p>',
              '<p><u>Some underline</u></p>',
              '<p></p>',
              '<p></p>',
              '<h1>Embedded 2</h1>',
              '<p></p>',
              '<p>Some raw content</p>',
              '<p></p>',
              '<p>An unpublished embed:</p>',
              '<p></p>',
              '<p>Some more content</p>',
              '<p><code>Some code</code></p>',
              '<p><a href="https://www.contentful.com">A hyperlink</a></p>',
              '<ul><li><p>Ul list</p></li><li><p>A few <b>items</b></p><ol><li><p>Ordered list nested inside an Unordered list item</p></li></ol></li></ul>',
              '<ol><li><p>Ol list</p></li><li><p>two</p></li><li><p>three</p></li></ol>',
              '<hr />',
              '<p></p>',
              '<blockqoute><p>An inspirational quote</p><p></p></blockqoute>',
              '<p></p>'
            ].join("\n")

            client = Contentful::Client.new(
              space: 'jd7yc4wnatx3',
              access_token: '6256b8ef7d66805ca41f2728271daf27e8fa6055873b802a813941a0fe696248',
              dynamic_entries: :auto,
              gzip_encoded: false
            )
            entry = client.entry('4BupPSmi4M02m0U48AQCSM')

            expect(subject.rich_text(entry.body)).to eq expected_default
            expect(subject.rich_text(entry.body, 1)).to eq expected_different_config
          }
        end
      end
    end
  end
end
