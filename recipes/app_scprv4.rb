#
# Cookbook Name:: scpr-apps
# Recipe:: app_scprv4
#
# Copyright (c) 2014 Southern California Public Radio, All Rights Reserved.

scpr_apps "scprv4" do
  action      :run
  capistrano  true
  ruby        "2.1"
  app_type    :rails

  roles({
    web: ->(key,name,dir,config) {
      include_recipe "nginx_passenger"

      # Call nginx setup
      # FIXME: Need to configure max workers here
      nginx_passenger_site "scprv4" do
        action      :create
        dir         "#{dir}/current"
        server      config.hostname
        rails_env   key
        log_format  "combined_timing"
      end

      # -- consul advertising -- #

      scpr_consul_web_service name do
        action    :create
        dir       dir
        hostname  config.hostname
        path      "/"
        interval  '5s'
      end
    },
    worker: ->(key,name,dir,config) {
      # Set up resque pool
      include_recipe "lifeguard"

      lifeguard_service "SCPRv4 Resque (#{key})" do
        action        [:enable,:start]
        service       "scprv4-#{key}-resque"
        user          name
        dir           dir
        monitor_dir   "#{dir}/current"
        command       "bundle exec resque-pool"
        path          "#{dir}/bin"
        env({
          "TERM_CHILD"  => 1,
          "RAILS_ENV"   => name
        })
      end

      # Set up rufus-scheduler


    },
  })

end