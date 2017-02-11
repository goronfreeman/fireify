require 'rails/generators'
require 'rails/generators/migration'
require 'rails/generators/active_record'

module Fireify
  module Generators
    class InstallGenerator < Rails::Generators::Base
      include Rails::Generators::Migration
      extend Rails::Generators::Migration

      source_root File.expand_path('../../templates', __FILE__)
      desc 'Creates Fireify initializer for your application'

      def self.next_migration_number(path)
        ActiveRecord::Generators::Base.next_migration_number(path)
      end

      def copy_initializer
        template 'initializer.rb', 'config/initializers/fireify.rb'

        # TODO: Write a post install message
      end

      def copy_migration
        migration_template 'migration.rb', 'db/migrate/fireify_create_users.rb', migration_version: migration_version
      end

      def migration_data
<<-RUBY
      t.string :email, null: false, default: ''
      t.string :name, null: false, default: ''
      t.string :profile_picture, null: false, default: ''
      t.string :firebase_id, null: false, default: ''
RUBY
      end

      def rails5?
        Rails.version.start_with?('5')
      end

      def migration_version
        return unless rails5?
        "[#{Rails::VERSION::MAJOR}.#{Rails::VERSION::MINOR}]"
      end
    end
  end
end
