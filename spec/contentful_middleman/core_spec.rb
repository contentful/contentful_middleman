require 'spec_helper'

class MapperDouble
end

describe ContentfulMiddleman::Core do
  subject { described_class.new Middleman::Application.new }
  let(:options) { subject.options }

  before(:each) do
    ContentfulMiddleman.instance_variable_set(:@contentful_middleman_instances, [])
  end

  describe 'options' do
    it 'defaults' do
      expect(options.space).to eq(nil)
      expect(options.access_token).to eq(nil)
      expect(options.cda_query).to eq({})
      expect(options.content_types).to eq({})
      expect(options.use_preview_api).to eq(false)
      expect(options.all_entries).to eq(false)
      expect(options.rebuild_on_webhook).to eq(false)
      expect(options.webhook_timeout).to eq(300)
    end
  end

  describe 'hooks' do
    describe '#after_configuration' do
      before do
        options.space = {some_name: 'some_id'}
      end

      it 'updates space data from original hash' do
        subject.after_configuration

        expect(options.space).to match(name: :some_name, id: 'some_id')
      end

      describe 'updates content type data' do
        it 'uses base mapper when only id is set' do
          options.content_types = {
            some_content_type_name: 'some_id'
          }

          subject.after_configuration

          expect(options.content_types).to match('some_id' => {name: :some_content_type_name, mapper: ContentfulMiddleman::Mapper::Base})
        end

        it 'uses custom mapper' do
          options.content_types = {
            some_content_type_name: {
              id: 'some_id',
              mapper: MapperDouble
            }
          }

          subject.after_configuration

          expect(options.content_types).to match('some_id' => {name: :some_content_type_name, mapper: MapperDouble})
        end
      end

      it 'sets up instances' do
        expect(ContentfulMiddleman.instances.size).to eq(0)

        subject.after_configuration

        expect(ContentfulMiddleman.instances.size).to eq(1)
      end
    end
    describe 'webhook handler' do
      it 'does not get called if rebuild_on_webhook is false' do
        expect(ContentfulMiddleman::WebhookHandler).not_to receive(:start)

        subject.app.execute_callbacks(:before_server)
      end

      it 'gets called if rebuild_on_webhook is true' do
        options.rebuild_on_webhook = true

        expect(ContentfulMiddleman::WebhookHandler).to receive(:start)

        subject.app.execute_callbacks(:before_server)
      end
    end
  end
end
