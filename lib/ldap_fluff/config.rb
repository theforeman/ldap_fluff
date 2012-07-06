require 'singleton'
require 'yaml'

class LdapFluff
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
                  :port,
                  :encryption,
                  :base_dn,
                  :group_base,
                  :server_type,
                  :ad_domain,
                  :service_user,
                  :service_pass,
                  :anon_queries

    def initialize
      begin
        config = YAML.load_file(LdapFluff::CONFIG)
        @host = config["host"]
        @port = config["port"]
        if config["encryption"].respond_to? :to_sym
          @encryption = config["encryption"].to_sym
        else
          @encryption = nil
        end
        @base_dn = config["base_dn"]
        @group_base = config["group_base"]
        @ad_domain = config["ad_domain"]
        @service_user = config["ad_service_user"]
        @service_pass = config["ad_service_pass"]
        @anon_queries = config["ad_anon_queries"]
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
