require "hashie/mash"

module SCPRAppsStore
  def self.stash(config)
    @@config = config
  end

  def self.stashed
    @@config || nil
  end

  def self.load_for(node)
    config = nil
    if File.exists?(node.scpr_apps.config_file)
      config = begin JSON.parse(File.read(node.scpr_apps.config_file)) rescue nil end
      config = Hashie::Mash.new config
    end

    config
  end

  def self.save_for(node,config)
    File.open(node.scpr_apps.config_file,"w") do |f|
      f << JSON.pretty_generate(config)
    end

    true
  end
end
