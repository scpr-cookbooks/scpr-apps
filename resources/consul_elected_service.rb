actions :start, :stop, :restart, :remove
default_action :enable

attribute :name,          :kind_of => String, :name_attribute => true
attribute :service,       :kind_of => String
attribute :user,          :kind_of => String
attribute :server,        :kind_of => String
attribute :key,           :kind_of => String
attribute :watch,         :kind_of => String, :default => nil
attribute :command,       :kind_of => String
attribute :cwd,           :kind_of => String
attribute :env,           :kind_of => Hash
attribute :path,          :kind_of => String
attribute :restart,       :kind_of => [TrueClass, FalseClass], :default => true
attribute :watch_restart, :kind_of => [TrueClass, FalseClass], :default => true
attribute :verbose,       :kind_of => [TrueClass, FalseClass], :default => true
attribute :depends,       :kind_of => String, :default => nil