module Pageclip
  class Configuration
    attr_accessor :api_key
    attr_accessor :api_endpoint
    attr_accessor :client_timeout
    attr_accessor :job_defaults
    attr_accessor :logger

    def initialize
      reset!
    end

    # Test-Only: Used to clear the configuration values to their
    # defaults
    def reset!
      @api_key = nil
      @api_endpoint = 'http://api.pageclip.io'
      @client_timeout = 61 # Maximum API request time is 60s
      @job_defaults = {}
      @logger = nil
    end
  end
end
