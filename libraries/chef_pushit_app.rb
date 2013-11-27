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

      DATA_BAG = 'pushit_apps'.freeze

      def initialize(name)
        @app = Pushit.app_data_bag(name)
      end

      def apps_path
        ::File.join(Pushit.pushit_path, 'apps')
      end

      def config
        data_bag_item = Chef::DataBagItem.load(DATA_BAG, @app['id'])
        data_bag_item || {}
      end

      def user
        @user ||= Pushit::User.new(@app['owner'])
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

      def pid_path
        ::File.join(path, 'shared', 'pids')
      end

      def socket_path
        ::File.join(path, 'shared', 'sockets')
      end

      # def pid_path

      #   path = '/opt/pushit/apps/eirenerx-vagrant/shared/tmp/pids'

      #   unless File.directory?(::File.join(path))
      #     FileUtils.mkdir_p(path, :mode => 0700)
      #   end
      # end

      # def socket_path

      #   Chef::Log.warn shared_path

      #   unless File.directory?(::File.join(shared_path, 'tmp', 'sockets'))
      #     FileUtils.mkdir_p(
      #       ::File.join(shared_path, 'tmp', 'sockets'), :mode => 0700
      #     )
      #   end
      # end

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
