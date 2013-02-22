require 'net/http'
require 'uri'
require 'benchmark'

require 'pageclip/version'
require 'pageclip/configuration'
require 'pageclip/errors'

module Pageclip
  class << self
    def configure
      yield(configuration)
    end

    # Public: The current configuration for the Pageclip service.
    #
    # Returns a Pageclip::Configuration representing the current
    # configuration.
    def configuration
      @configuration ||= Pageclip::Configuration.new
    end

    # Public: Requests a screenshot from synchronously.
    #
    # options:
    #   :canvas_width
    #   :canvas_height
    #   :viewport_width
    #   :viewport_height
    #   :thumbnail_width
    #   :thumbnail_height
    #   :timeout
    #   :secret
    #
    def screenshot(url, options={})
      time = nil
      response = nil

      begin
        Timeout::timeout(@configuration.client_timeout) {
          request_options = @configuration.job_defaults || {}
          request_options[:api_key] = @configuration.api_key
          request_options.merge!(options)

          request_options[:url] = url

          uri = URI.parse(@configuration.api_endpoint)
          uri.path = '/v1/screenshots/'
          uri.query = request_options.map { |k,v| "#{URI.escape(k.to_s)}=#{URI.escape(v.to_s)}" }.join("&")

          http = Net::HTTP.new(uri.host, uri.port)
          request = Net::HTTP::Get.new(uri.request_uri)

          time = Benchmark.realtime do
            response = http.request(request)
          end

          if response.code == "403"
            raise Pageclip::UnauthorizedError
          elsif response.code == "429"
            raise Pageclip::RateLimitedError
          end
        }
      rescue Timeout::Error
        raise Pageclip::TimeoutError
      ensure
        log("[Pageclip #{response ? response.code : '-'} #{time ? time : '?'}s] Requested #{url}")
      end
    end
    private

    def log(message)
      return unless @configuration.logger

      @configuration.logger.info(message)
    end
  end
end
