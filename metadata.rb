name             'scpr-apps'
maintainer       'Southern California Public Radio'
maintainer_email 'erichardson@scpr.org'
license          'all_rights'
description      'Installs/Configures scpr-apps'
long_description 'Installs/Configures scpr-apps'
version          '0.2.21'

depends "apt"
depends "nginx_passenger", "~> 0.5.5"
depends "lifeguard"
depends "scpr-consul"
depends "scpr-tools"
depends "nodejs"
depends "python", "~> 1.4.6"
depends "logrotate"
depends "scpr-logstash-forwarder"
depends "runit"
depends "scpr-java"
depends "libarchive"
