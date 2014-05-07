# encoding: utf-8

require 'minitest/autorun'
require 'minitest/spec'

describe 'pushit_test::ruby' do

  it 'has successfully installed ruby_build' do
    assert system(
      'su - deploy -c "which ruby-build"'
    )
  end

  it 'has successfully installed chruby' do
    assert system(
      'su - deploy -c "which chruby-exec"'
    )
  end

  it 'has created chruby.sh' do
    assert ::File.read(
      '/etc/profile.d/chruby.sh'
    ).include?('1.9.3-p448')
  end

  it 'chruby.sh sources auto.sh' do
    assert ::File.read(
      '/etc/profile.d/chruby.sh'
    ).include?('auto.sh')
  end

  let(:rubies_path) { ::File.join('', 'opt', 'pushit', 'rubies') }

  it 'has created a rubies directory' do
    assert File.directory?(rubies_path)
  end

  let(:mri_binary) do
    ::File.join(rubies_path, '1.9.3-p448', 'bin', 'ruby')
  end

  it 'has successfully installed mri' do
    assert system(
      "#{mri_binary} -v | grep -e '1.9.3p448'"
    )
  end

  it 'has successfully installed bundler' do
    assert system(
      'su - deploy -c "which bundle"'
    )
  end

  it 'has successfully installed foreman' do
    assert system(
      'su - deploy -c "which foreman"'
    )
  end

  it 'has successfully installed unicorn' do
    assert system(
      'su - deploy -c "which unicorn"'
    )
  end
end
