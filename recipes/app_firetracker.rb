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
  deploy_key  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC8z5/0wlR7UcQ3/C8yqLTIEuvUepGfTnmLMxNYvINu7kXZQxTThR4VR9utkXwzGDNiubKmYjdUnX/hT40W82DKg/RjoQFKiJ0zYfcwYTc1dLzvsEoTkjAkVQLCgFSON7DWDsQQ1+ynkz30FFgFCOJurivfcMZ+nZRyUQTMZAyNiSv93lGwfGO27dWwf8JF66Ic11Zbse+ZCetiBuWMMs1dqEIT9siBHNNgc3cC4VzQlcT/s02j8NcWEn30eaoWUF6GrVgMwCEue5n1FEbqasoQce3o6u3VkJjv6fb3ayk3XyYNEhotnEk9dt966AZ/aQ66jQEK5eHYIst2hpoLHEMl firetracker-deploy@scpr"
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