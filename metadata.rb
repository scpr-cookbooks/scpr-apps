name             'scpr-apps'
maintainer       'Southern California Public Radio'
maintainer_email 'erichardson@scpr.org'
license          'all_rights'
description      'Installs/Configures scpr-apps'
long_description 'Installs/Configures scpr-apps'
version          '0.1.9'

depends "apt"
depends "nginx_passenger"
depends "lifeguard"
depends "scpr-consul"