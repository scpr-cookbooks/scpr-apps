#
# Cookbook Name:: scpr-apps
# Recipe:: app_ois
#
# Copyright (c) 2014 Southern California Public Radio, All Rights Reserved.

scpr_apps "ois" do
  action      :run
  capistrano  true
  ruby        "2.1"
  app_type    :rails
  deploy_key  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC7Xrm+7yW5Gh4CCLpwnZEZ+y1TdrFktxLhtTsZZ5aRvegB1oTX39opswNpK4vKe/kV7qrYNETl1b+ZJbtQmWL+xoONyJ+YAlCSx/mxp8tUWfpIzpGaNbXDgRL2BU6jSvQy9K/2/XpsCIqXzVKLQh1Gmy7As89tYuq2xM1bKtCf41CoQlypXo62sx5evf2+SC8gADD26zE6hz9mPlG/yfQ4lXp8T5QB4GCoAttTgXhL5cJvx+K8e7nxN4dyFa3hmPzsEbGUarP8rfGqZy24q/y2MjoqVR/WTYroWhwhSqslTbMFjVgZgGDb8dXCG0O/b66W66FQb89hbaHYCgnpCj7n ois_deploy@scpr"

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

      #scpr_consul_web_service name do
      #  action    :create
      #  dir       "#{dir}/current"
      #  hostname  config.hostname
      #  path      "/"
      #  interval  '5s'
      #end

      consul_service_def "#{name}_web" do
        action    :create
        port      80
        tags      ["web"]
        notifies  :reload, "service[consul]"
      end

      # just here to get us db migrations
      consul_service_def "#{name}_worker" do
        action    :create
        tags      ["worker"]
        notifies  :reload, "service[consul]"
      end

    },
  })

end