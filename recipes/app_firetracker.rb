#
# Cookbook Name:: scpr-apps
# Recipe:: app_firetracker
#
# Copyright (c) 2014 Southern California Public Radio, All Rights Reserved.

package "libmysqlclient-dev"
include_recipe "python"

scpr_apps "firetracker" do
  action      :run
  capistrano  true
  app_type    :django
  deploy_key  ""
  bash_path   "!DIR!/virtualenv/bin"

  setup ->(key,name,dir,config,env) {
    python_virtualenv "#{dir}/virtualenv" do
      action  :create
      owner   name
      group   name
    end

    python_pip "ez_setup" do
      action      :install
      virtualenv  "#{dir}/virtualenv"
    end

    env.merge!({
      FIRETRACKER_CONFIG_PATH:  "#{dir}/current/#{config}/#{key}.yml",
      VIRTUAL_ENV:              "#{dir}/virtualenv",
    })
  }

  roles({
    web: ->(key,name,dir,config) {
      include_recipe "scpr-apps::_nginx"

      # Call nginx setup
      nginx_passenger_site name do
        action      :create
        dir         "#{dir}/current"
        server      "#{config.hostname} #{name}_web.service.consul"
        log_format  "combined_timing"
        env         key
        user        name
      end

      # -- consul advertising -- #

      scpr_consul_web_service name do
        action    :create
        dir       "#{dir}/current"
        hostname  config.hostname
        path      "/"
        interval  '30s'
      end
    },
    worker: ->(key,name,dir,config) {

    },
  })
end