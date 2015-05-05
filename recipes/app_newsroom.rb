#
# Cookbook Name:: scpr-apps
# Recipe:: app_newsroom
#

scpr_apps "newsroom" do
  action      :run
  capistrano  true
  app_type    :nodejs
  deploy_key  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDFg6RFA82jWWHG1Njiixl2Sk08P4mcSa6VwwjZvvX8nejuYHWHWGL+tdVXXM1YQTIkZ9I6zOxEaLrYSsawIPNbVN7Xzmu02mhdQADPNxgvFAgWFy8NZ0JxaPQ5lFw1Yo8Y3YkRyaNIt2roi2r3cVoQedtwYa6HMuyXXcggJFNoZP8EoUVCY0ZSbNemqSxPK5WAibghxmSNzQVtEIURoIjFmiH6IAuRNDoJSPQrstAVCb1AU/AePxHtrwWDO0OEAeHjYiQ4VhNRrcIamCqQGho2oA2b13p9pDYln3FpEhX3yHqGMRhHk4++IIYlUAizpuLSGfBLBMn5NgREDMcwXcLb newsroom_deploy@scpr"

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

      consul_service_def "#{name}_web" do
        action    [:create]
        tags      ["newsroom"]
        notifies  :reload, "service[consul]"
      end
    },
  })
end