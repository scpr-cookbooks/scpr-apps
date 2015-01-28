#
# Cookbook Name:: scpr-apps
# Recipe:: app_assethost
#
# Copyright (c) 2014 Southern California Public Radio, All Rights Reserved.

package "libcurl4-openssl-dev"

scpr_apps "streamdash" do
  action      :run
  capistrano  true
  ruby        "2.1"
  app_type    :rails
  deploy_key  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7lNvd+uE+/083Coa9x39aDea81PxcBEhHgeESsfhG0HbEeo5aYlJ9Ynr4oTjBr1jSFg4tnIeukCQBsiqM6MwRntyDK1eA/sTBZK4/vSNstk62ip2BIfDdhEtjf+1bUKxGvsUSMGcOpv9OMFMebRaZbmmzr3HbwB2XzsPr5I8O64GnpqvKmxcT1i3XFe2isgLhcEZVDamKRZNZQSbxksLFFM4QvZlNN9NY8HRDxj/b04p8UWI7lldlxzETpE/rXAvq55ny1Jwip//qtQwtqnWiYyMUc2yrbr0vYGdr08O6VG5tFKSRMqNUtbBphaj98DWVL1vbN1bOesGcJZgAAlxn sm-dashboard-deploy@scpr"

  setup ->(key,name,dir,config,env) {
    logrotate_app name do
      cookbook  "logrotate"
      path      ["#{dir}/shared/log/*.log"]
      size      100*1024*1024
      rotate    3
      options   ["missingok","compress","copytruncate"]
    end
  }

  roles({
    web: ->(key,name,dir,config) {
      include_recipe "scpr-apps::_nginx"

      # Call nginx setup
      nginx_passenger_site name do
        action        :create
        dir           "#{dir}/current"
        server        "#{config.hostname} #{name}_web.service.consul"
        rails_env     key
        log_format    "combined_timing"
      end

      # -- consul advertising -- #

      scpr_consul_web_service name do
        action    :create
        dir       "#{dir}/current"
        hostname  config.hostname
        path      "/"
        interval  '5s'
      end
    },
  })

end