require 'rails/generators'

module Fireify
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('../../templates', __FILE__)
      desc 'Creates Fireify initializer for your application'

      def copy_initializer
        template 'initializer.rb', 'config/initializers/fireify.rb'

        # TODO: Write a post install message
      end
    end
  end
end
