# encoding: utf-8

require 'minitest/autorun'
require 'minitest/spec'

describe 'pushit_test::ruby' do

  let(:rubies_path) { ::File.join('', 'opt', 'pushit', 'rubies') }

  it 'has created a rubies directory' do
    assert File.directory?(rubies_path)
  end

  let(:mri_binary) do
    ::File.join(rubies_path, '1.9.3-p392', 'bin', 'ruby')
  end

  it 'has successfully installed mri' do
    assert system(
      "#{mri_binary} -v | grep -e '1.9.3p392'"
    )
  end

  it 'has created pushit_ruby.sh' do
    assert File.read(
      '/etc/profile.d/pushit_ruby.sh'
    ).include?('1.9.3')
  end

  let(:ree_binary) do
    ::File.join(rubies_path, 'ree-1.8.7-2012.02', 'bin', 'ruby')
  end

  it 'has successfully installed ree' do
    assert system(
      "#{ree_binary} -v | grep -e '1.8.7'"
    )
  end

  it 'has created pushit_ruby.sh' do
    assert File.read(
      '/etc/profile.d/pushit_ruby.sh'
    ).include?('1.8.7')
  end
end
