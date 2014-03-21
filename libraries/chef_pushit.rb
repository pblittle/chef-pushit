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

require ::File.expand_path('../chef_pushit_app', __FILE__)

class Chef
  module Pushit

    PUSHIT_USER ||= 'deploy'.freeze
    PUSHIT_GROUP ||= 'deploy'.freeze
    PUSHIT_PATH ||= ::File.join('', 'opt', 'pushit').freeze
    PUSHIT_DATA_BAG ||= 'pushit_apps'.freeze
    PUSHIT_RUBY_DEFAULT ||= '2.0.0-p353'
    PUSHIT_GEM_DEPENDENCIES ||= %w{ bundler foreman unicorn }.freeze

    class << self

      def pushit_user
        @pushit_user ||= PUSHIT_USER
      end

      def pushit_group
        @pushit_group ||= PUSHIT_GROUP
      end

      def pushit_path
        @pushit_path ||= PUSHIT_PATH
      end

      def whyrun_enabled?
        @whyrun_enabled ||= false
      end

      # This should be an encrypted data bag
      def app_data_bag(name)
        data_bag_item = Chef::DataBagItem.load(PUSHIT_DATA_BAG, name)
        data_bag_item || {}
      end
    end

    class Nodejs

      def self.prefix_path
        ::File.join('', 'usr', 'local')
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

    class Ruby

      attr_accessor :version
      attr_accessor :rubies_path
      attr_accessor :prefix_path
      attr_accessor :bin_path
      attr_accessor :gem_path
      attr_accessor :ruby_binary
      attr_accessor :bundle_binary
      attr_accessor :foreman_binary

      def initialize(version)
        @version = version
        @rubies_path = rubies_path
        @prefix_path = prefix_path
        @bin_path = bin_path
        @ruby_binary = ruby_binary
        @bundle_binary = bundle_binary
        @foreman_binary = foreman_binary
        @unicorn_binary = unicorn_binary
      end

      def version
        @version ||= PUSHIT_RUBY_DEFAULT
      end

      def rubies_path
        ::File.join(Pushit.pushit_path, 'rubies')
      end

      def prefix_path
        ::File.join(@rubies_path, version)
      end

      def bin_path
        ::File.join(@prefix_path, 'bin')
      end

      def ruby_binary
        ::File.join(@bin_path, 'ruby')
      end

      def bundle_binary
        ::File.join('bundle')
      end

      def foreman_binary
        ::File.join('foreman')
      end

      def unicorn_binary
        ::File.join('unicorn')
      end

      def gem_path(executable)
        ::File.join(bin_path, executable)
      end
    end

    class Certs
      def self.certs_path
        ::File.join(Pushit.pushit_path, 'ssl')
      end

      def self.certs_directory
        ::File.join(certs_path, 'certs')
      end

      def self.keys_directory
        ::File.join(certs_path, 'private')
      end
    end
  end
end
