module Pageclip
  class Configuration
    attr_accessor :api_key
    attr_accessor :api_endpoint
    attr_accessor :client_timeout
    attr_accessor :job_defaults
    attr_accessor :logger

    def initialize
      @api_endpoint = 'http://api.pageclip.io'
      @client_timeout = 61 # Maximum API request time is 60s
    end
  end
end
