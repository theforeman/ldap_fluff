require 'singleton'
require 'yaml'

module LdapFluff
  ####################################################################
  # Module constants
  ####################################################################
  CONFIG = "/etc/ldap_fluff.yml"
  ####################################################################
  # Module class definitions
  ####################################################################
  class Config
    include Singleton
    attr_accessor :host,
                  :encryption,
                  :base,
                  :group_base,
                  :ad_domain,
                  :server_type

    def initialize
      begin
        config = YAML.load_file(LdapFluff::CONFIG)
        @host = config["host"]
        @encryption = config["encryption"]
        @base = config["base"]
        @group_base = config["group_base"]
        @ad_domain = config["ad_domain"]
        @server_type = config["server_type"]
      rescue Errno::ENOENT
        $stderr.puts("The #{LdapFluff::CONFIG} config file you specified was not found")
        exit
      rescue Errno::EACCES
        $stderr.puts("The #{LdapFluff::CONFIG} config file you specified is not readable")
        exit
      end
    end
  end
end
