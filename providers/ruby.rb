include Chef::DSL::IncludeRecipe
use_inline_resources # ~FC113

action :install do
  include_recipe "apt"
  include_recipe "libarchive"

  if new_resource.version =~ /^jruby-(\d.*)/
    # java needs to be installed... our wrapper cookbook has our settings
    include_recipe "scpr-java"

    jruby_version = $~[1]

    # make sure our install_path dir exists
    directory node.scpr_apps.jruby_install_path do
      action :create
      recursive true
    end

    archive = remote_file "travis-#{new_resource.version}.tar.gz" do
      action  :create_if_missing
      path    ::File.join(Chef::Config[:file_cache_path], "#{new_resource.version}.tar.gz")
      source  "https://s3.amazonaws.com/jruby.org/downloads/9.0.4.0/jruby-bin-#{jruby_version}.tar.gz"
    end

    # top-level in these archives is a folder, so we'll end up with something
    # like /opt/jruby-9.0.4.0
    libarchive_file archive.path do
      extract_to node.scpr_apps.jruby_install_path
      extract_options [:permissions,:no_overwrite]
    end

    # Install bundler, convolutedly passing a path to gem via jruby, since otherwise
    # there's no jruby in our PATH
    gem_package "bundler" do
      action      :install
      gem_binary  "#{node.scpr_apps.jruby_install_path}/#{new_resource.version}/bin/jruby #{node.scpr_apps.jruby_install_path}/#{new_resource.version}/bin/gem"
      options     "-n #{node.scpr_apps.jruby_install_path}/#{new_resource.version}/bin"
    end
  else
    # make sure the brightbox PPA is added

    apt_repository  "brightbox-ruby-ng" do
      uri           "http://ppa.launchpad.net/brightbox/ruby-ng/ubuntu"
      distribution  node['lsb']['codename'] #~FC019
      components    ["main"]
      keyserver     "hkp://keyserver.ubuntu.com:80"
      key           "C3173AA6"
    end

    packages = []

    packages << "ruby#{new_resource.version}"
    packages << "ruby#{new_resource.version}-dev"
    #packages << "rubygems"

    packages.each do |p|
      package p do
        action :install
      end
    end

    gem_package "bundler" do
      action      :install
      gem_binary  "/usr/bin/gem#{new_resource.version}"
      options     "--format-executable -n /usr/bin"
    end
  end
end

action :link do
  if !new_resource.dir
    raise "Cannot link ruby without target directory."
  end

  directory new_resource.dir do
    action    :create
    recursive true
  end

  if new_resource.version =~ /^jruby-(\d.*)/
    ["jruby","jgem","irb","gem","rake","bundle"].each do |bin|
      link "#{new_resource.dir}/#{bin}" do
        to      "#{node.scpr_apps.jruby_install_path}/#{new_resource.version}/bin/#{bin}"
        action  :create
      end
    end

    link "#{new_resource.dir}/ruby" do
      to "#{node.scpr_apps.jruby_install_path}/#{new_resource.version}/bin/jruby"
      action :create
    end
  else
    ["ruby","irb","gem","rake","bundle"].each do |bin|
      link "#{new_resource.dir}/#{bin}" do
        to      "/usr/bin/#{bin}#{new_resource.version}"
        action  :create
      end
    end
  end

end
