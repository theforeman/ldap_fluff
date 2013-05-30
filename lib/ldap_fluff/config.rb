require 'yaml'

class LdapFluff
  class ConfigError < StandardError
  end

  class Config
    ATTRIBUTES = %w[host port encryption base_dn group_base server_type ad_domain service_user
                    service_pass anon_queries]
    ATTRIBUTES.each { |attr| attr_reader attr.to_sym }

    def initialize(config)
      raise ArgumentError unless config.respond_to? :to_hash
      config = validate convert(config)

      ATTRIBUTES.each do |attr|
        instance_variable_set :"@#{attr}", config[attr]
      end
    end

    private

    # @param [#to_hash] config
    def convert(config)
      config.
          to_hash.
          inject({}) { |hash, (k, v)| hash.update k.to_s => v }.
          tap do |config|
        %w[encryption server_type].each do |key|
          config[key] = config[key].to_sym if config[key]
        end
      end
    end

    DEFAULT_CONFIG = { 'port'         => 389,
                       'encryption'   => nil,
                       'base_dn'      => 'dc=company,dc=com',
                       'group_base'   => 'dc=company,dc=com',
                       'server_type'  => :free_ipa,
                       'ad_domain'    => nil,
                       'anon_queries' => false }

    def validate(config)
      config = DEFAULT_CONFIG.merge config

      missing_keys = ATTRIBUTES - config.keys
      missing_keys.empty? or
          raise ConfigError, "missing configuration for keys: #{missing_keys.join ','}"

      unknown_keys = config.keys - ATTRIBUTES
      unknown_keys.empty? or
          raise ConfigError, "unknown configuration keys: #{unknown_keys.join ','}"

      %w[host port base_dn group_base server_type service_user service_pass].all? do |key|
        config[key].nil? and
            raise ConfigError, "config key #{key} has to be set, it was nil"
      end

      [:posix, :active_directory, :free_ipa].include? config['server_type'] or
          raise ConfigError,
                'config key server_type has to be :active_directory, :posix, :free_ipa ' +
                    "but was #{config['server_type']}"

      [false, true].include? config['anon_queries'] or
          raise ConfigError,
                "config key anon_queries has to be true or false but was #{config['anon_queries']}"
      return config
    end
  end
end
