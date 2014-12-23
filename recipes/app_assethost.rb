#
# Cookbook Name:: scpr-apps
# Recipe:: app_assethost
#
# Copyright (c) 2014 Southern California Public Radio, All Rights Reserved.

package "libmysqlclient-dev"
package "libcurl4-openssl-dev"

scpr_apps "assethost" do
  action      :run
  capistrano  true
  ruby        "2.1"
  app_type    :rails
  deploy_key  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDM8L0cgqJlAc2AIaPNGB/3LdwFxcPXgGgtOZN3oJyfuLhgI6SOfcN0SoHwvmb0HIp2kSyESFTBLI4gyzJGziEqiwg38uEIRuL3M3JjrxqihQESfCiRkvPH9DQrekYYQE6Vbc+ZdIeAQ/ioZTpABANRLsv908DoYtBC4A7r1UUJu9Y4wBxLqIz+mcJ2xe2z0c0aQfINKhxt8YrF4I3xCOdRuKulktMs7MKZnvjr0/TGsUAWSeGbUUF6xvBo4Arny5DGOJcpx8uHIzIVpK1DV/Dn3r/jE6p3JLh3yXABote+yLDPgFDPvW+yEDPVlmISQbIf58RnAmT5p4mKABBNfO1z assethost_deploy@scpr"

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
      # FIXME: Need to configure max workers here
      nginx_passenger_site name do
        action        :create
        dir           "#{dir}/current"
        server        config.hostname
        rails_env     key
        log_format    "combined_timing"
        max_body_size "40M"
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
    worker: ->(key,name,dir,config) {
      # Set up resque pool
      include_recipe "lifeguard"

      # Make sure imagemagick is available
      package "imagemagick"
      package "libmagickwand-dev"
      package "libimage-exiftool-perl"

      # exiftool?

      lifeguard_service "AssetHost Resque (#{key})" do
        action        [:enable,:start]
        service       "assethost-#{key}-resque"
        user          name
        dir           dir
        monitor_dir   "#{dir}/current"
        command       "bundle exec resque-pool"
        path          "#{dir}/bin"
        env({
          "TERM_CHILD"  => 1,
          "RAILS_ENV"   => key
        })
      end

      # -- register service -- #

      consul_service_def "#{name}_worker" do
        action    :create
        tags      ["worker"]
        notifies  :reload, "service[consul]"
      end

      # Set up scheduler


    },
  })

end