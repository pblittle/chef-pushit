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
        @app = Pushit.app_data_bag(name)
      end

      def apps_path
        ::File.join(Pushit.pushit_path, 'apps')
      end

      def config
        data_bag_item = Chef::DataBagItem.load(PUSHIT_DATA_BAG, @app['id'])
        data_bag_item || {}
      end

      def user
        @user ||= Pushit::User.new(@app['owner'])
      end

      def ruby
        @ruby ||= Pushit::Ruby.new(@app['ruby'])
      end

      def name
        @app['id']
      end

      def path
        ::File.join(apps_path, @app['id'])
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
        if procfile?
          ::File.join(path, 'shared', 'log')
        else
          ::File.join(path, 'shared', 'log', "#{app.name}.log")
        end
      end

      def log_dir
        ::File.join(path, 'shared', 'log')
      end

      def pid_path
        ::File.join(path, 'shared', 'pids')
      end

      def upstart_pid
        ::File.join(pid_path, 'upstart.pid')
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
        File.join(
          '', 'etc', 'init', "#{name}.conf"
        )
      end

      def foreman_export_flags
        args = []
        args << 'upstart /etc/init'
        args << "-f #{procfile}"
        args << "-e #{envfile}"
        args << "-a #{name}"
        args << "-u #{@app['owner']}"
        args << "-l #{log_path}"
        args.join(' ')
      end

      def upstream_socket
        ::File.join(path, 'shared', 'sockets', 'unicorn.sock')
      end

      def upstream_port
        @app['webserver']['upstream_port'] || 8080
      end

      def http_port
        @app['webserver']['http_port'] || 80
      end

      def https_port
        @app['webserver']['https_port'] || 443
      end

      def has_webserver?
        @app['webserver'] && !@app['webserver'].empty?
      end

      def has_webserver_certificate?
        self.has_webserver? && @app['webserver']['certificate'] &&
          !@app['webserver']['certificate'].empty?
      end

      def webserver_certificate
        has_webserver_certificate? ? @app['webserver']['certificate'] : nil
      end

      def has_database?
        @app['database'] && !@app['database'].empty?
      end

      def has_database_certificate?
        self.has_database? && @app['database']['certificate'] &&
          !@app['database']['certificate'].empty?
      end

      def database_certificate
        has_database_certificate? ? @app['database']['certificate'] : nil
      end

      def server_name
        @app['webserver']['server_name'] || '_'
      end

      def root
        ::File.join(current_path, 'public')
      end

      def version
        cached_copy_dir = ::File.join(shared_path, 'cached-copy')

        if ::File.directory?(::File.join(cached_copy_dir, '.git'))
          Dir.chdir(cached_copy_dir) do
            `git rev-parse HEAD`.chomp
          end
        end
      end
    end
  end
end
