# encoding: utf-8

name 'pushit'
maintainer 'P. Barrett Little'
maintainer_email 'barrett@barrettlittle.com'
license 'Apache 2.0'
description 'Installs/Configures Internet Applications'
long_description IO.read(
  File.join(
    File.dirname(__FILE__),
    'README.md'
  )
)
version '0.1.0'

supports 'debian'
supports 'ubuntu'

depends 'git'
depends 'logrotate'
depends 'monit'
depends 'nodejs'
depends 'database'
depends 'nginx'
depends 'ruby_build'
depends 'runit'
depends 'ssh_known_hosts'

recommends 'apt'
recommends 'build-essential'
