# encoding: utf-8
#
# Cookbook Name:: pushit
# Library:: chef_pushit_ruby
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
  module Pushit
    class Ruby

      PUSHIT_RUBY_DEFAULT ||= '2.0.0-p481'

      attr_reader :version
      attr_reader :environment

      attr_accessor :rubies_path
      attr_accessor :prefix_path
      attr_accessor :bin_path
      attr_accessor :ruby_binary
      attr_accessor :gem_binary
      attr_accessor :foreman_binary
      attr_accessor :unicorn_binary

      def initialize(args = {})
        args = { version: args } if args.is_a?(String)

        @version = args['version'] || PUSHIT_RUBY_DEFAULT
        @environment = args['environment'] || {}
      end

      def rubies_path
        ::File.join(Pushit.pushit_path, 'rubies')
      end

      def prefix_path
        ::File.join(rubies_path, version)
      end

      def bin_path
        ::File.join(prefix_path, 'bin')
      end

      def embedded_bin_path
        ::File.join('', 'opt', 'chef', 'embedded', 'bin')
      end

      def deployment_bin_paths
        [embedded_bin_path, bin_path].join(':')
      end

      def ruby_binary
        ::File.join(bin_path, 'ruby')
      end

      def gem_binary
        ::File.join(bin_path, 'gem')
      end

      def foreman_binary
        ::File.join(embedded_bin_path, 'foreman')
      end

      def unicorn_binary
        ::File.join(embedded_bin_path, 'unicorn')
      end

      def bundle_binary
        ::File.join(embedded_bin_path, 'bundle')
      end

      def bundle_command(command)
        require 'bundler'

        Bundler.with_clean_env do
          output = `"#{bundle_binary}" #{command}`
          print output
        end
      end
    end
  end
end
