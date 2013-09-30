# encoding: utf-8
#
# Cookbook Name:: pushit
# Library:: chef_pushit
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

require 'fileutils'

class Pushit

  DATA_BAG = 'pushit_apps'.freeze
  PUSHIT_PATH = '/opt/pushit'.freeze
  WHYRUN_ENABLED = false

  class << self
    def pushit_path
      @pushit_path || PUSHIT_PATH
    end

    def whyrun_enabled?
      @whyrun_enabled || WHYRUN_ENABLED
    end
  end

  class App
    def initialize(name)
      @app = Pushit.app_data_bag(name)
    end

    def self.apps_path
      ::File.join(Pushit.pushit_path, 'apps')
    end

    def config
      data_bag_item = Chef::DataBagItem.load(DATA_BAG, @app['id'])
      data_bag_item || {}
    end

    def path
      ::File.join(Pushit::App.apps_path, @app['id'])
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

  class Rails < Pushit::App
    def initialize(name)
      super
    end
  end

  class Nodejs < Pushit::App
    def initialize(name)
      super
    end

    def self.prefix_path
      ::File.join('', 'usr','local')
    end

    def self.bin_path
      ::File.join(prefix_path, 'bin')
    end

    def self.node_binary
      ::File.join(bin_path, 'node')
    end

    def self.npm_binary
      ::File.join(bin_path, 'npm')
    end
  end

  class Ruby < Pushit::App

    attr_accessor :version
    attr_accessor :rubies_path
    attr_accessor :prefix_path
    attr_accessor :bin_path
    attr_accessor :ruby_binary
    attr_accessor :gem_path

    def initialize(version = nil)
      @version = version
      @rubies_path = rubies_path
      @prefix_path = prefix_path
      @bin_path = bin_path
      @ruby_binary = ruby_binary
    end

    def rubies_path
      ::File.join(Pushit.pushit_path, 'rubies')
    end

    def prefix_path
      ::File.join(@rubies_path, @version)
    end

    def bin_path
      ::File.join(@prefix_path, 'bin')
    end

    def ruby_binary
      ::File.join(@bin_path, 'ruby')
    end

    def gem_path(executable)
      ::File.join(bin_path, executable)
    end
  end

  class User < Pushit::App
    def initialize(name)
    end

    def self.user
      'deploy'
    end

    def self.group
      'deploy'
    end

    def self.home_path
      ::File.join(Pushit.pushit_path)
    end
  end

  class Certs < Pushit::App
    def initialize(name)
      
    end

    def certs_path
      ::File.join(Pushit.pushit_path, 'certs')
    end
  end

  class<< self

    # We should have a dryer way to build configs
    def create_config(file, attrs); end

    # We need to dry up the rails definition env
    def app_environment(app); end

    # This should be an encrypted data bag
    def app_data_bag(name)
      data_bag_item = Chef::DataBagItem.load(DATA_BAG, name)
      data_bag_item || {}
    end
  end
end
