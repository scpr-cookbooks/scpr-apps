#
# Cookbook Name:: scpr-apps
# Recipe:: app_projects
#
# Copyright (c) 2015 Southern California Public Radio, All Rights Reserved.

scpr_apps "projects" do
  action      :run
  capistrano  true
  app_type    :static
  deploy_key  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDmHLKzlQe7OjorunaB/2ZZUZXclmiCBKI59rjs5gpDAmzXnlaYymp8aHvxF+7Guk8P+bx6BTvq6EEAdqMzjuJMTnCfc4aoC2L5RQCOjxqHq0bW571ZzKVmnen7lMCq4Qa2w41mfr4S6F9W8MoFF31KUFoz2mfioYswCyZHU5axqTCrosYG6YlynkFM+78L3PXm6DEgjdayynOlbZbwBBq2E18ioxnSqLITEUR2b1QNbvvoL+2lB99VBJJWRoKDo5YPuuPRCVKF08rJzm5HLl4wubWFMIrAvHJlUz2Z2ToZXOngNBiszm45jJGTOo/DW+N+oB/N1/MYvcD8sDI1SA4Z projects-deploy@scpr"

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
        static        true
        template      "projects_site.conf.erb"
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