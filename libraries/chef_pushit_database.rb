# encoding: utf-8
#
# Cookbook Name:: pushit
# Library:: database
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
    class Database

      def initialize(args = {})
        @args = args
      end

      def to_hash
        config.reject do |_, value|
          value.nil? || value.empty?
        end
      end

      def config
        {
          :adapter => adapter,
          :database => database,
          :host => host,
          :port => port,
          :username => username,
          :password => password,
          :encoding => encoding,
          :sslkey => sslkey,
          :sslcert => sslcert,
          :sslca => sslca
        }.merge(options)
      end

      def adapter
        @adapter ||= @args['adapter']
      end

      def database
        @database ||= @args['database']
      end

      def host
        @host ||= @args['host']
      end

      def port
        @port ||= @args['port'].to_s
      end

      def username
        @username ||= @args['username']
      end

      def password
        @password ||= @args['password']
      end

      def encoding
        @encoding ||= @args['encoding'] || 'utf8'
      end

      def sslkey
        @sslkey ||= @args['sslkey'] || options['sslkey']
      end

      def sslcert
        @sslcert ||= @args['sslcert'] || options['sslcert']
      end

      def sslca
        @sslca ||= @args['sslca'] || options['sslca']
      end

      private

      def options
        @args['options'] || {}
      end
    end
  end
end
