module Pageclip
  class Configuration
    attr_accessor :api_key
    attr_accessor :api_endpoint
    attr_accessor :job_defaults
    attr_accessor :logger

    def initialize
      @api_endpoint = 'http://api.pageclip.io'
    end
  end
end
