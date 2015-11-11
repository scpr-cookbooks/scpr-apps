#
# Cookbook Name:: scpr-apps
# Recipe:: app_firetracker
#
# Copyright (c) 2014 Southern California Public Radio, All Rights Reserved.

package "libmysqlclient-dev"
include_recipe "python"

scpr_apps "earthquakes" do
  action      :run
  capistrano  true
  app_type    :django
  deploy_key  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC1UYjWvFWxQjM3FQUREKQb0AubFrziIw4VkemcPUVD4yFHaj1SQ0e94NG7RoXFPqACQn8niShRrRL/8ZT8avvySR9/cPjH+C/xbUNHbhSzn8Oq5tzI58tYX1cw8uK13ECzxITaA80p0WBP/PLvt5H4yDNKjFmHl9gOC6/eX0FmwaTT8CqGzAaukj6csx08DUUIismZYt7nUmUg319CZ7FAG9xoIDRSLSgEhX0R64AHsma/H3htKlg9zWi/rRVUl6iZ5PwkrRJZ6OagexV9rwhd04eMAmlBI0BO6/BRCUmO3nCgsBDU74WKIUneoX6YBjzfe1j+2GCV3RJiYR37X+Lj earthquakes-deploy@scpr"
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
      CONFIG_PATH:  "#{dir}/current/config/#{key}.yml",
      VIRTUAL_ENV:  "#{dir}/virtualenv",
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

      # -- logstash-forwarder -- #

      log_forward name do
        paths ["#{node.nginx_passenger.log_dir}/#{name}.access.log"]
        fields({
          type: "nginx",
          app:  "earthquakes",
          env:  key,
        })
      end
    },
    worker: ->(key,name,dir,config) {
      consul_service_def "#{name}_worker" do
        action    :create
        tags      ["worker"]
        notifies  :reload, "service[consul]"
      end
    },
  })
end