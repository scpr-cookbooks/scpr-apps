default.scpr_apps.databag     = 'scpr_apps'
default.scpr_apps.config      = nil
default.scpr_apps.config_file = "/etc/scpr_apps.json"

default.scpr_apps.media_path  = "/scpr/media"

default.scpr_apps.base_path   = "/scpr"

default.scpr_apps.ruby.versions['2.0'] = "2.0.0.451-1bbox1~precise1"
default.scpr_apps.ruby.versions['2.1'] = "2.1.4-1bbox1~precise2"

default.scpr_apps.consul_enabled  = true
default.scpr_apps.nfs_enabled     = true

#----------

include_attribute "nginx_passenger"

default.nginx_passenger.log_dir   = "/scpr/log"
default.nginx_passenger.sites_dir = "/etc/nginx/sites"