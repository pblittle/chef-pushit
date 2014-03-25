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
version '0.4.172'

supports 'debian'
supports 'ubuntu'

depends 'campfire-deployment'
depends 'certificate'
depends 'git'
depends 'monit'
depends 'logrotate'
depends 'nodejs'
depends 'database'
depends 'newrelic-deployment'
depends 'nginx'
depends 'rsyslog'
depends 'rbenv'
depends 'ruby_build'
depends 'runit'
depends 'ssh'
depends 'ssh_known_hosts'
depends 'sudo'

recommends 'apt'
recommends 'build-essential'
