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

          time = Benchmark.realtime do
            begin
              response = get("#{@configuration.api_endpoint}/v1/screenshots/", request_options)
            rescue EOFError, Errno::ETIMEDOUT, Errno::ECONNREFUSED
              if attempt = ( attempt || 1) and attempt <= 3
                Kernel.sleep(attempt)
                attempt += 1
                retry
              else
                raise Pageclip::ServiceUnavailableError
              end
            end
          end

          if response.code == "403"
            raise Pageclip::UnauthorizedError
          elsif response.code == "429"
            raise Pageclip::RateLimitedError
          elsif response.code == "503"
            raise Pageclip::ServiceUnavailableError
          elsif response.code == "302"
            time += Benchmark.realtime do
              begin
                response = get(response['location'])
              rescue EOFError, Errno::ETIMEDOUT, Errno::ECONNREFUSED
                if attempt = ( attempt || 1) and attempt <= 3
                  Kernel.sleep(attempt)
                  attempt += 1
                  retry
                else
                  raise Pageclip::ServiceUnavailableError
                end
              end
            end
          end

          if response.code == "410" || response.code == "202"
            raise Pageclip::ScreenshotError
          elsif response.code == "503"
            raise Pageclip::ServiceUnavailableError
          elsif response.code == "301"
            response['location']
          else
            raise Pageclip::Error
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

    def get(url, query={})
      uri = URI.parse(url)
      unless query.empty?
        uri.query = query.map { |k,v| "#{URI.escape(k.to_s)}=#{URI.escape(v.to_s)}" }.join("&")
      end

      http = Net::HTTP.new(uri.host, uri.port)
      request = Net::HTTP::Get.new(uri.request_uri)
      request['User-Agent'] = "Pageclip Ruby #{VERSION}"
      http.request(request)
    end
  end
end
