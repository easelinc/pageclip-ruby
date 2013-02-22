require 'pageclip/version'
require 'pageclip/configuration'

module Pageclip
  class << self
    def configure
      yield(configuration)
    end

    def configuration
      @configuration ||= Pageclip::Configuration.new
    end
  end
end
