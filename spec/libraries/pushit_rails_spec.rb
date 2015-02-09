require 'spec_helper'

describe 'pushit_test::rails' do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(
      :step_into => %w(pushit_rails pushit_app pushit_base)
    ).converge(described_recipe) do
      # Must stub this method so that we can get a "version" for pushit without actually pulling git code
      allow_any_instance_of(Chef::Pushit::App).to receive(:version).and_return(app_version)
    end
  end

  let(:app_version) do
    'IamAdummyVersionOfYourApp'
  end

  before do

    # Need a default stub for the databag.load method or we get errors.
    allow(Chef::DataBagItem).to receive(:load).and_return(Hash.new)

    # Ensure we're not looking for the app databags anymore
    expect(Chef::DataBagItem).to_not(receive(:load).with('pushit_apps', 'rails-example'))

    allow(Chef::DataBagItem).to(
      receive(:load).with('users', 'deploy').and_return(
        'id' =>  'deploy',
        'comment' =>  'Application Deployer',
        'ssh_private_key' =>  '-----BEGIN RSA PRIVATE KEY-----',
        'ssh_public_key' =>  'ssh-rsa',
        'ssh_deploy_keys' =>  [
          {
            'name' =>  'id_rsa_rails-example',
            'data' =>  '-----BEGIN RSA PRIVATE KEY-----\n=rails-example-deploy-key\n-----END RSA PRIVATE KEY-----'
          }
        ],
        'ssh_keys' =>  [
          'ssh-rsa == foo',
          'ssh-rsa == bar'
        ]
      )
    )
  end

  app_path = ::File.join %w( / opt pushit apps rails-example )
  shared_path = ::File.join app_path, 'shared'
  config_path = ::File.join shared_path, 'config'

  PUSHIT_APP_GEM_DEPENDENCIES =
    [
      { :name => 'bundler', :version => '1.7.2' },
      { :name => 'foreman', :version => '0.74.0' },
      { :name => 'unicorn', :version => '4.8.3' }
    ].freeze

  PUSHIT_APP_GEM_DEPENDENCIES.each do |gem|
    it "installs the #{gem[:name]} gem" do
      expect(chef_run).to install_chef_gem(gem[:name])
    end

    it "restarts the app when #{gem[:name]} gem is installed or updated" do
      expect(chef_run.chef_gem(gem[:name])).to(
        notify('service[rails-example]').to(:restart).delayed
      )
    end
  end

  it 'creates the app directory' do
    expect(chef_run).to create_directory(app_path)


    require 'pp'
    puts "\n\n*****************************\n*\n*"
    pp chef_run.node[:pushit_test]
    puts "\n*\n*\n*\n****************************"





  end

  it 'creates the app shared directory' do
    expect(chef_run).to create_directory(shared_path)
  end

  it "creates the shared directories in '#{shared_path}'" do
    %w( cached-copy config system vendor_bundle log pids sockets ).each do |dir|
      expect(chef_run).to create_directory(::File.join(shared_path, dir))
    end
  end

  it 'creates the ruby-version file' do
    expect(chef_run).to create_template(::File.join(shared_path, 'ruby-version'))
  end

  # TODO: do we need to re-do the foreman stuff too??
  it 'restarts the app if the ruby version changes' do
    expect(chef_run.template(::File.join(shared_path, 'ruby-version'))).to(
      notify('service[rails-example]').to(:restart).delayed)
  end

  it 'installs ruby' do
    expect(chef_run).to create_pushit_ruby('2.1.1')
  end

  it 'restarts the app if the ruby changes' do
    expect(chef_run.pushit_ruby('2.1.1')).to notify('service[rails-example]').to(:restart).delayed
  end

  it 'adds the database config' do
    expect(chef_run).to create_template(::File.join(config_path, 'database.yml'))
  end

  it 'restarts the app if the database config changes' do
    expect(chef_run.template(::File.join(config_path, 'database.yml'))).to(
      notify('service[rails-example]').to(:restart).delayed)
  end

  it 'creates the database ssl cert' do
    expect(chef_run).to create_certificate_manage('database-cert').with(
        :cert_path => '/opt/pushit/ssl',
        :cert_file => 'database-cert.crt',
        :chain_file => 'database-cert.chain',
        :key_file => 'database-cert.key'
      )
  end

  # TODO: restart the app, or run foreman??, or does the database config template change and we get this free?
  it 'restarts the app if the database certificate changes' do
    expect(chef_run.certificate_manage('database-cert')).to(
      notify('service[rails-example]').to(:restart).delayed
    )
  end

  it 'adds the filestore config' do
    expect(chef_run).to create_template(::File.join(config_path, 'filestore.yml'))
  end

  it 'restarts the app if the filestore config changes' do
    expect(chef_run.template(::File.join(config_path, 'filestore.yml'))).to(
      notify('service[rails-example]').to(:restart).delayed
    )
  end

  it 'adds the unicorn config' do
    expect(chef_run).to create_template(::File.join(config_path, 'unicorn.rb'))
  end

  # TODO: this doesn't impact foreman, does it??
  it 'restarts the app if the unicron config changes' do
    expect(chef_run.template(::File.join(config_path, 'unicorn.rb'))).to(
      notify('service[rails-example]').to(:restart).delayed
    )
  end

  it 'creates a vhost config for the app' do
    expect(chef_run).to create_pushit_vhost('rails-example')
  end

  it 'creates the env file' do
    expect(chef_run).to create_template(::File.join(shared_path, 'env'))
  end

  it 'runs foreman export' do
    expect(chef_run).to run_foreman_export('rails-example')
  end

  it 'restarts the app if foreman runs' do
    expect(chef_run.foreman_export('rails-example')).to notify('service[rails-example]').to(:restart).delayed
  end

  it 'creates the resources custom config files' do
    expect(chef_run).to create_cookbook_file(::File.join(app_path, 'releases', app_version, 'test_file.txt'))
  end

  it 'restarts the app if any config files change' do
    expect(chef_run.cookbook_file(::File.join(app_path, 'releases', app_version, 'test_file.txt'))).to(
      notify('service[rails-example]').to(:restart).delayed)
  end

  it 'creates the procfile for rails-example app' do
    expect(chef_run).to create_file('rails-example Procfile')
  end

  it 'deploys the app' do
    expect(chef_run).to deploy_deploy_revision('rails-example')
  end

  it 'creates a service config for the app' do
    expect(chef_run.service('rails-example'))
  end

  it 'starts the app service' do
    allow(::File).to receive(:exist?)
    allow(::File).to receive(:exist?).with('/etc/init/rails-example.conf').and_return(true)
    expect(chef_run).to start_service('rails-example')
  end
end
