# encoding: utf-8
#
# Cookbook Name:: pushit
# Library:: app
#
# Author:: P. Barrett Little (<barrett@barrettlittle.com>)
#
# Copyright 2013, P. Barrett Little
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

require_relative 'chef_pushit'

class Chef
  # pushit module
  module Pushit
    # Model class for pushit apps
    class App
      include Mixin::App
      require 'chef/mixin/deep_merge'

      def initialize(name, config)
        @name = name
        @config =
          if config.is_a?(Hash)
            config
          else
            config.reduce(Mash.new) { |a, e| Chef::Mixin::DeepMerge.merge(a, e) }
          end
      end

      attr_reader :config

      def user
        @user ||= Pushit::User.new(config['owner'])
      end

      def ruby
        ruby_version = config['ruby'] || {}
        @ruby ||= Pushit::Ruby.new(ruby_version)
      end

      def database?
        !database.nil?
      end

      def database_certificate
        database.certificate
      end

      def database_config
        raise Exception, "No database configuration available for #{name}" unless database?
        database.to_hash
      end

      attr_reader :name

      def path
        ::File.join(Pushit.pushit_apps_path, @name)
      end

      def current_path
        ::File.join(path, 'current')
      end

      def release_path
        ::File.join(path, 'releases', version)
      end

      def shared_path
        ::File.join(path, 'shared')
      end

      def log_path
        ::File.join(shared_path, 'log')
      end

      def shared_directories
        %w( cached-copy config system vendor_bundle log pids sockets )
      end

      def pid_path
        ::File.join(shared_path, 'pids')
      end

      def upstart_pid
        ::File.join(pid_path, 'upstart.pid')
      end

      def bin_paths
        [
          ruby.bin_path,
          bundler_binstubs_path,
          nodejs_bin_path
        ].join(':')
      end

      def env_vars
        e = config['env'] || {}
        e.merge(bundle_env_vars)
      end

      def envfile
        ::File.join(release_path, '.env')
      end

      def procfile
        ::File.join(release_path, 'Procfile')
      end

      def procfile?
        ::File.exist?(procfile)
      end

      def procfile_default_entry(framework)
        case framework
        when 'rails'
          'web: bundle exec unicorn -p $PORT -c ./config/unicorn.rb'
        when 'nodejs'
          'web: npm start'
        else
          raise "Unknown pushit framework '#{framework}"
        end
      end

      def foreman_export_flags
        args = []
        args << 'upstart /etc/init'
        args << "-e #{envfile}"
        args << "-a #{name}"
        args << "-d #{release_path}"
        args << "-r #{pid_path}"
        args << "-u #{config['owner']}"
        args << "-l #{log_path}"
        args.join(' ')
      end

      def upstream_socket
        ::File.join(path, 'shared', 'sockets', 'unicorn.sock')
      end

      def upstream_port
        config['webserver']['upstream_port'] || 8080
      end

      def http_port
        config['webserver']['http_port'] || 80
      end

      def https_port
        config['webserver']['https_port'] || 443
      end

      def webserver?
        config['webserver'] && !config['webserver'].empty?
      end

      def webserver_certificate?
        webserver? && config['webserver']['certificate'] &&
          !config['webserver']['certificate'].empty?
      end

      def webserver_certificate
        webserver_certificate? ? config['webserver']['certificate'] : nil
      end

      def server_name
        config['webserver']['server_name'] || '_'
      end

      def root
        ::File.join(current_path, 'public')
      end

      def version
        raise Exception, "#{current_path} symlink does not exist" unless ::File.symlink?(current_path)

        Pathname.new(current_path).realpath.basename
      end

      private

      def database
        @database ||= config['database'] ? Pushit::Database.new(config['database']) : nil
      end
    end
  end
end
