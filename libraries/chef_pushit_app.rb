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

require ::File.expand_path('../chef_pushit', __FILE__)

class Chef
  module Pushit
    class App

      def initialize(name)
        @name = name
      end

      def config
        @config ||= Pushit.app_data_bag(@name)
      end

      def user
        @user ||= Pushit::User.new(config['owner'])
      end

      def ruby
        @ruby ||= Pushit::Ruby.new(ruby_version)
      end

      def ruby_version
        config['ruby'] || PUSHIT_RUBY_DEFAULT
      end

      def name
        @name ||= config['id']
      end

      def gem_dependencies
        @gem_dependencies ||= PUSHIT_GEM_DEPENDENCIES
      end

      def path
        ::File.join(Pushit.pushit_apps_path, config['id'])
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

      def vendor_path
        ::File.join(release_path, 'vendor')
      end

      def log_path
        ::File.join(shared_path, 'log')
      end

      def pid_path
        ::File.join(shared_path, 'pids')
      end

      def bundler_binstubs_path
        ::File.join(vendor_path, 'bundle', 'bin')
      end

      def upstart_pid
        ::File.join(pid_path, 'upstart.pid')
      end

      def env_vars
        config['env'] || {}
      end

      def envfile
        ::File.join(release_path, '.env')
      end

      def procfile
        ::File.join(release_path, 'Procfile')
      end

      def procfile?
        ::File.exists?(procfile)
      end

      def service_config
        ::File.join('', 'etc', 'init', "#{name}.conf")
      end

      def foreman_export_flags
        args = []
        args << "upstart /etc/init"
        args << "-f #{procfile}"
        args << "-e #{envfile}"
        args << "-a #{name}"
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
        self.webserver? && config['webserver']['certificate'] &&
          !config['webserver']['certificate'].empty?
      end

      def webserver_certificate
        webserver_certificate? ? config['webserver']['certificate'] : nil
      end

      def database?
        config['database'] && !config['database'].empty?
      end

      def database_certificate?
        self.database? && config['database']['certificate'] &&
          !config['database']['certificate'].empty?
      end

      def database_certificate
        database_certificate? ? config['database']['certificate'] : nil
      end

      def server_name
        config['webserver']['server_name'] || '_'
      end

      def root
        ::File.join(current_path, 'public')
      end

      def cached_copy_dir
        ::File.join(shared_path, 'cached-copy')
      end

      def version
        if ::File.directory?(::File.join(cached_copy_dir, '.git'))
          Dir.chdir(cached_copy_dir) do
            `git rev-parse HEAD`.chomp
          end
        end
      end
    end
  end
end
