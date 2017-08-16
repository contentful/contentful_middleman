require 'spec_helper'

class HelpersMock
  include ContentfulMiddleman::Helpers
end

class InstanceDouble
end

describe ContentfulMiddleman::Helpers do
  let(:entry) do
    {
      _meta: {
        id: 'foo',
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
              id: 'foo',
            },
            name: {
              'es' => 'foo',
              'en-US' => 'bar'
            }
          }, {
            id: 'foo',
            _meta: {
              id: 'foo',
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
            id: 'foo',
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
        expect(subject.localize_entry(entry, 'es')).to eq({
          _meta: { id: 'foo' },
          value_field: 'foo',
          array_field: ['foobar'],
          nested_array: [
            {
              id: 'foo',
              _meta: {
                id: 'foo',
              },
              name: 'foo'
            }, {
              id: 'foo',
              _meta: {
                id: 'foo',
              },
              name: 'foo',
            }
          ],
          nested_hash: {
            id: 'foo',
            _meta: {
              id: 'foo',
            },
            name: 'foo'
          }
        })
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
  end
end
