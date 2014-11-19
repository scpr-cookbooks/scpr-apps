actions :loop
default_action :run

attribute :name,        kind_of:String
attribute :capistrano,  kind_of:[TrueClass,FalseClass], default:false
attribute :ruby,        kind_of:[String,FalseClass], default:false
attribute :roles,       kind_of:Hash
attribute :delete,      kind_of:Hash
attribute :bash_path,   kind_of:String
attribute :base_path,   kind_of:String, default:node.scpr_apps.base_path
attribute :app_type,    kind_of:Symbol
attribute :env,         kind_of:Hash