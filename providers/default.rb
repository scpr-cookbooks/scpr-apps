include Chef::DSL::IncludeRecipe

#use_inline_resources

def set_up_config(&block)
  (SCPRAppsStore.stashed[new_resource.name]||[]).each do |key,app_config|
    # turn scprv4 and prod into "scprv4_prod"
    name = [ new_resource.name, key ].join("_")

    # set up our directory path
    dir = [ new_resource.base_path, name ].join("/")

    # pull any settings values from Consul
    (SCPRAppsStore.pull_consul_settings("#{new_resource.name}/#{key}")||{}).each do |k,v|
      app_config[k] = v
    end

    yield key, name, dir, app_config
  end
end

action :run do
  set_up_config do |key,name,dir,app_config|
    puts "Running config for #{key} || #{name} || #{dir} || #{app_config}"

    # -- create user -- #

    user name do
      action  :create
      system  true
      shell   "/bin/bash"
      home    dir
    end

    # -- home directory -- #

    directory dir do
      action    :create
      owner     name
      mode      0755
      recursive true
    end

    directory "#{dir}/bin" do
      action  :create
      owner   name
      mode    0755
    end

    # -- Install a ruby? -- #

    if new_resource.ruby
      scpr_apps_ruby new_resource.ruby do
        action  [:install,:link]
        dir     "#{dir}/bin"
      end
    end

    # -- bash config -- #

    template "#{dir}/.bash_profile" do
      action  :create
      mode    0644
      owner   name
      source  "bash_profile.erb"
      variables({
        key:key, name:name, dir:dir, app_config:app_config, resource:new_resource
      })
    end

    # -- Capistrano Directories? -- #

    if new_resource.capistrano
      ['releases','shared','shared/system','shared/log','shared/pids'].each do |path|
        directory "#{dir}/#{path}" do
          action  :create
          owner   name
          mode    0755
        end
      end
    end

    # -- Deploy Credentials -- #

    # -- Roles? -- #

    puts "app roles is #{ app_config.roles }"
    (app_config.roles||[]).each do |r|
      puts "role is #{r}"
      if new_resource.roles[ r.to_sym ]
        puts "calling role"
        instance_exec(key,name,dir,app_config,&new_resource.roles[ r.to_sym ])
      else
        raise "Invalid role for SCPR app: #{new_resource.name}/#{r}"
      end
    end
  end
end
