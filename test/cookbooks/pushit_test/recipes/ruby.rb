# encoding: utf-8
#
# Cookbook Name:: pushit_test
# Recipe:: ruby
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

include_recipe 'pushit_test::base'

pushit_ruby '1.9.3-p448'

pushit_ruby 'ree-1.8.7-2012.02' do
  environment({
    'CONFIGURE_OPTS' => '--no-tcmalloc'
  })
  chruby_environment({
    'RUBY_GC_MALLOC_LIMIT' => '50000000'
  })
end
