# encoding: utf-8
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

if defined?(ChefSpec)
  def create_pushit_nodejs(app_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :pushit_nodejs,
      :create,
      app_name
    )
  end

  def create_pushit_rails(app_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :pushit_rails,
      :create,
      app_name
    )
  end

  def create_pushit_ruby(ruby_version)
    ChefSpec::Matchers::ResourceMatcher.new(
      :pushit_ruby,
      :create,
      ruby_version
    )
  end

  def create_pushit_user(user_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :pushit_user,
      :create,
      user_name
    )
  end

  def create_pushit_vhost(app_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :pushit_vhost,
      :create,
      app_name
    )
  end

  def create_pushit_webserver(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(
      :pushit_webserver,
      :create,
      resource_name
    )
  end
end