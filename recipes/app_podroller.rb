#
# Cookbook Name:: scpr-apps
# Recipe:: app_streammachine
#
# Copyright (c) 2014 Southern California Public Radio, All Rights Reserved.

scpr_apps "podroller" do
  action      :run
  capistrano  true
  app_type    :nodejs
  deploy_key  "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQDpmYA/rTy2/u49QiEch+xFV0CcKRyIxbWGcV/wFiRi9Ih9Pdwt2xO1IaxGlnq/AS3utE80itsHqOu0vS3hOxj7+aDkkJ3SsropBSsUhIwZP4MPEJPD3O89PiQ0jGD5lrJemBhgk7D/oStI71VGCSE7my7GTJohMYSNVzCTqVNcITbrEaygoV2z95lZw1KKgYTHUZ0M79nDSqL/OOcmfR4H694NhhOWelUqBmfMtPuGTPNie8viTTAEBPav6VDnSd3S0tN1p4c9j6sAu6Gf0ZVHGBfakXX9jxRO3AGylGdMaZv8ornDZxsZp/FaaL0Mv/42ouLwSQhWimGX8+xmhwGj podroller-deploy@scpr"

  setup ->(key,name,dir,config,env) {
    include_recipe "lifeguard"

    if node.scpr_apps.nfs_enabled
      include_recipe "nfs"
      scpr_tools_media_mount "#{dir}/audio" do
        action :create
        remote_path "/scpr/media/audio"
      end
    end
  }

  roles({
    web: ->(key,name,dir,config) {
      lifeguard_service "Podroller (#{key})" do
        action        [:enable,:start]
        service       "podroller-#{key}"
        command       "env ./runner-cmd --config=./config/podroller.json"
        user          name
        dir           dir
        monitor_dir   "#{dir}/current"
        handoff       true
        restart       true
      end

      consul_service_def "#{name}" do
        action    [:create]
        tags      ["podroller"]
        notifies  :reload, "service[consul]"
      end
    },
  })
end