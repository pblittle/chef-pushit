# encoding: utf-8

require 'minitest/autorun'
require 'minitest/spec'

describe 'pushit_test::ssl' do

  let(:certs_path) {
    ::File.join('', 'opt', 'pushit', 'certs')
  }

  let(:ca_path) { ::File.join(certs_path, 'test-ca.pem') }
  let(:cert_path) { ::File.join(certs_path, 'test-cert.pem') }
  let(:key_path) { ::File.join(certs_path, 'test-key.pem') }

  it 'has created a ca file' do
    assert ::File.read(ca_path).include?('test-ca')
  end

  it 'has created a cert file' do
    assert ::File.read(cert_path).include?('test-cert')
  end

  it 'has created a key file' do
    assert ::File.read(key_path).include?('test-key')
  end
end
