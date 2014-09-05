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
    # model class for pushit ruby
    class Ruby
      RUBY_DEFAULT_VERSION ||= '2.0.0-p481'
      BUNDLER_DEFAULT_VERSION ||= '1.7.2'

      attr_reader :version
      attr_reader :environment
      attr_reader :bundler_version

      def initialize(args = {})
        args = { 'version' => args } if args.is_a?(String)

        @version = args['version'] || RUBY_DEFAULT_VERSION
        @bundler_version = args['bundler_version'] || BUNDLER_DEFAULT_VERSION
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

      def ruby_binary
        ::File.join(bin_path, 'ruby')
      end

      def gem_binary
        ::File.join(bin_path, 'gem')
      end
    end
  end
end
