require 'spec_helper'

describe Chef::Provider::PushitVhost do
  let(:chef_run) do
    ChefSpec::SoloRunner.new(
      :step_into => %w(pushit_vhost)
    ).converge('pushit_test::vhost')
  end

  before do
    allow(Chef::DataBagItem).to(
      receive(:load)
    )

    allow(Chef::DataBagItem).to(
      receive(:load).with('pushit_apps', 'rails-example').and_return(
        'id' => 'rails-example'
      )
    )

    allow(Chef::DataBagItem).to(
      receive(:load).with('pushit_apps', 'nodejs-example').and_return(
        'id' => 'nodejs-example'
      )
    )

    allow(Chef::DataBagItem).to(
      receive(:load).with('users', 'deploy').and_return(
        'id' => 'deploy',
        'comment' => 'Application Deployer',
        'ssh_private_key' => '-----BEGIN RSA PRIVATE KEY-----',
        'ssh_public_key' => 'ssh-rsa',
        'ssh_deploy_keys' => [
          {
            'name' => 'id_rsa_rails-example',
            'data' => '-----BEGIN RSA PRIVATE KEY-----\n=rails-example-deploy-key\n-----END RSA PRIVATE KEY-----'
          }
        ],
        'ssh_keys' => [
          'ssh-rsa == foo',
          'ssh-rsa == bar'
        ]
      )
    )
  end

  let(:resource_vhost) do
    chef_run.template('/opt/pushit/nginx/sites-available/rails-example.conf')
  end

  it 'creates a vhost config' do
    expect(chef_run).to create_pushit_vhost('rails-example')
  end

  it 'adds a nginx site' do
    pending 'need to figure out the matchers for this because it is a definition rather than a resource'
    expect(chef_run).to enable_nginx_site('/opt/pushit/nginx/sites-available/rails-example.conf')
  end

  it 'notifes nginx reload if vhost config changes' do
    vhost_config = chef_run.template('/opt/pushit/nginx/sites-available/rails-example.conf')
    expect(vhost_config).to notify('pushit_webserver[nginx]').to(:reload).delayed
  end

  context 'without ssl' do
    it 'does not create the webserver ssl cert' do
      expect(chef_run).not_to create_certificate_manage('dummy')
    end
  end

  context 'with ssl' do
    let(:chef_run) do
      runner = ChefSpec::SoloRunner.new(:step_into => %w(pushit_vhost))
      runner.node.set[:pushit_test_vhost_cert] = 'dummy'
      runner.converge('pushit_test::vhost')
    end

    it 'creates the webserver ssl cert' do
      expect(chef_run).to create_certificate_manage('dummy').with(
        :cert_path => '/opt/pushit/nginx/ssl',
        :cert_file => 'dummy-bundle.crt',
        :key_file => 'dummy.key'
      )
    end

    it 'restarts nginx if a new webserver cert is found' do
      expect(chef_run.certificate_manage('dummy')).to(
        notify('pushit_webserver[nginx]').to(:reload).delayed
      )
    end
  end
end
