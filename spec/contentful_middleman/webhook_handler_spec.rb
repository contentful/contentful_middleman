require 'spec_helper'

class ContentfulMiddleman::WebhookHandler
  def sleep(*)
    nil
  end

  def system(*)
    nil
  end
end

describe ContentfulMiddleman::WebhookHandler do
  subject { described_class.new ServerDouble.new, Logger.new(STDOUT), 10 }

  describe 'class methods' do
    it '::start' do
      expect(Contentful::Webhook::Listener::Server).to receive(:start)

      described_class.start webhook_timeout: 10
    end
  end

  describe 'instance methods' do
    it '#perform' do
      expect(subject.logger).to receive(:info).twice
      expect(subject).to receive(:sleep).with(10)
      expect(subject).to receive(:system).with('bundle exec middleman contentful --rebuild')
      subject.perform(RequestDouble.new, ResponseDouble.new)
    end
  end
end
