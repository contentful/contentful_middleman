require 'contentful/webhook/listener'

module ContentfulMiddleman
  class WebhookHandler < Contentful::Webhook::Listener::Controllers::Wait
    def perform(*)
      logger.info 'Webhook Received - Waiting for rebuild'
      super
      logger.info 'Rebuilding'
      system('bundle exec middleman contentful --rebuild')
    end

    def self.start(options)
      Contentful::Webhook::Listener::Server.start do |config|
        config[:endpoints] = [{
          endpoint: '/receive',
          timeout: options.webhook_timeout,
          controller: ::ContentfulMiddleman::WebhookHandler
        }]
        logger = Logger.new(STDOUT)
        logger.level = Logger::INFO
        logger.formatter = proc do |severity, datetime, progname, msg|
          date_format = datetime.strftime("%Y-%m-%d %H:%M:%S")
          if severity == "INFO"
            "Webhook Server: #{msg}\n"
          else
            "[#{date_format}] #{severity} (#{progname}): #{msg}\n"
          end
        end
        config[:logger] = logger
      end
    end
  end
end
