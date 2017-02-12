require 'fireify/configuration'
require 'fireify/version'
require 'fireify/verify'
require 'generators/fireify/install_generator'

module Fireify
  class << self
    attr_accessor :configuration
  end

  def self.configure
    self.configuration ||= Configuration.new
    yield(configuration)
  end
end
