require 'spec_helper'

describe service 'nginx' do
  it { should be_running.under('upstart') }
end
