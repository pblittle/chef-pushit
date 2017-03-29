# encoding: utf-8
require 'spec_helper'

context 'pushit_test::database' do
  it 'installs a mysql server' do
    expect(command('which mysql').exit_status).to eq(0)
  end

  it 'starts the mysqld process' do
    expect(service('mysqld')).to be_running
  end
end
