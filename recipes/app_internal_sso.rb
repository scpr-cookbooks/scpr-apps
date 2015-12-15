#
# Cookbook Name:: scpr-apps
# Recipe:: app_internal_sso
#
# Copyright (c) 2015 Southern California Public Radio, All Rights Reserved.

package "libmysqlclient-dev"
package "libcurl4-openssl-dev"

scpr_apps "internal_sso" do
  action      :run
  capistrano  true
  ruby        "2.1"
  app_type    :rails
  deploy_key  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDjaa4AW20aUOiVjGiDKaIj3qWWVQ8vYjF1afqZOP8VWkgbOXCnd9HP8mBwfOhw/vZ+hFAF3Di45GZ8WS5maxQC3UiIAugwNIVTPWfebYYHJHqTLKBqkqfei3Yg+ApdRTS6cxPqjvB+98uH11Eh5Tif1i8ytYy+IPRuQjnbX1SQqOrS/xd81c/CBMosIlXZj1xrEa8J1flZEClyfPsvC0D3CkzpoqPJgzVARw0l3mWRXbG7jUes0y5CmEQtKnpvrUcectjiN1SI30SdelORWoBhMu88IRM8JPXKo4o8ZKGKEh8Zpl3EELIdj7hnmJ4T3H7aSIGSpttAlhIWRbLRw7/r scpr_internal_sso-deploy@scpr"

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

      # -- logstash-forwarder -- #

      log_forward name do
        paths ["#{node.nginx_passenger.log_dir}/#{name}.access.log"]
        fields({
          type: "nginx",
          app:  "internal_sso",
          env:  key,
        })
      end

    },
    worker: ->(key,name,dir,config) {
      # -- register service -- #

      consul_service_def "#{name}_worker" do
        action    :create
        tags      ["worker"]
        notifies  :reload, "service[consul]"
      end

      # Set up scheduler
      scpr_apps_consul_elected_service "SCPRv4 Scheduler (#{key})" do
        action        [:enable,:start]
        service       "internal_sso-#{key}-scheduler"
        key           "internal_sso/#{key}/scheduler"
        user          name
        watch         "#{dir}/current/tmp/restart.txt"
        verbose       true
        command       "env PATH=#{dir}/bin:$PATH RAILS_ENV=#{key} bundle exec rake scheduler"
        cwd           "#{dir}/current"
      end
    },
  })

end