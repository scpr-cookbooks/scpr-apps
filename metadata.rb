name             'scpr-apps'
maintainer       'Southern California Public Radio'
maintainer_email 'erichardson@scpr.org'
source_url       'https://github.com/scpr-cookbooks/scpr-apps/'
issues_url       'https://github.com/scpr-cookbooks/scpr-apps/issues'
license          'All rights reserved'
description      'Installs/Configures scpr-apps'
long_description 'Installs/Configures scpr-apps'
supports         'ubuntu'
version          '0.2.31'

depends "apt"
depends "nginx_passenger", "~> 0.5.5"
depends "lifeguard"
depends "scpr-consul"
depends "scpr-tools"
depends "nfs", "= 2.4.0"
depends "nodejs"
depends "python", "~> 1.4.6"
depends "logrotate"
depends "scpr-logstash-forwarder"
depends "runit"
depends "scpr-java"
depends "libarchive", "~> 1.0.0"
