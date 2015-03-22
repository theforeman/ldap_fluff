require 'yaml'
require 'active_support/core_ext/hash'

class LdapFluff::Config
  ATTRIBUTES = %w[host port encryption base_dn group_base server_type service_user
                    service_pass anon_queries attr_login search_filter]
  ATTRIBUTES.each { |attr| attr_reader attr.to_sym }

  DEFAULT_CONFIG = { 'port'         => 389,
                     'encryption'   => nil,
                     'base_dn'      => 'dc=company,dc=com',
                     'group_base'   => 'dc=company,dc=com',
                     'server_type'  => :free_ipa,
                     'anon_queries' => false }

  def initialize(config)
    raise ArgumentError unless config.respond_to?(:to_hash)
    config = validate(convert(config))

    ATTRIBUTES.each do |attr|
      instance_variable_set(:"@#{attr}", config[attr])
    end
  end

  private

  # @param [#to_hash] config
  def convert(config)
    config.to_hash.with_indifferent_access.tap do |conf|
      %w[encryption server_type method].each do |key|
        conf[key] = conf[key].is_a?(Hash) ? convert(conf[key]) : conf[key].to_sym if conf[key]
      end
    end
  end

  def missing_keys?(config)
    missing_keys = ATTRIBUTES - config.keys
    raise ConfigError, "missing configuration for keys: #{missing_keys.join(',')}" unless missing_keys.empty?
  end

  def unknown_keys?(config)
    unknown_keys = config.keys - ATTRIBUTES
    raise ConfigError, "unknown configuration keys: #{unknown_keys.join(',')}" unless unknown_keys.empty?
  end

  def all_required_keys?(config)
    %w[host port base_dn group_base server_type].all? do |key|
      raise ConfigError, "config key #{key} has to be set, it was nil" if config[key].nil?
    end

    %w[service_user service_pass].all? do |key|
      if !config['anon_queries'] && config[key].nil?
        raise ConfigError, "config key #{key} has to be set, it was nil"
      end
    end
  end

  def anon_queries_set?(config)
    unless [false, true].include?(config['anon_queries'])
      raise ConfigError, "config key anon_queries has to be true or false but was #{config['anon_queries']}"
    end
  end

  def correct_server_type?(config)
    unless [:posix, :active_directory, :free_ipa].include?(config['server_type'])
      raise ConfigError, 'config key server_type has to be :active_directory, :posix, :free_ipa ' +
        "but was #{config['server_type']}"
    end
  end

  def validate(config)
    config = DEFAULT_CONFIG.merge(config)

    correct_server_type?(config)
    missing_keys?(config)
    unknown_keys?(config)
    all_required_keys?(config)
    anon_queries_set?(config)

    config
  end

  class ConfigError < LdapFluff::Error
  end
end
