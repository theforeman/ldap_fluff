# frozen_string_literal: true

class LdapFluff::Config
  ATTRIBUTES = [
    :host, :port, :encryption, :base_dn, :group_base, :server_type, :service_user, :service_pass,
    :anon_queries, :attr_login, :search_filter, :instrumentation_service, :use_netgroups
  ].freeze

  DEFAULT_CONFIG = {
    port: 389,
    encryption: nil,
    base_dn: 'dc=company,dc=com',
    group_base: 'dc=company,dc=com',
    server_type: :free_ipa,
    anon_queries: false,
    attr_login: nil,
    search_filter: nil,
    instrumentation_service: nil,
    use_netgroups: false
  }.freeze

  # @!attribute [rw] host
  #   @return [String]
  # @!attribute [rw] port
  #   @return [Integer]
  # @!attribute [rw] encryption
  #   @return [Symbol, Hash]
  # @!attribute [rw] base_dn
  #   @return [String]
  # @!attribute [rw] group_base
  #   @return [String]
  # @!attribute [rw] server_type
  #   @return [Symbol]
  # @!attribute [rw] service_user
  #   @return [String]
  # @!attribute [rw] service_pass
  #   @return [String]
  # @!attribute [rw] anon_queries
  #   @return [Boolean]
  # @!attribute [rw] attr_login
  #   @return [String]
  # @!attribute [rw] search_filter
  #   @return [String]
  # @!attribute [rw] instrumentation_service
  #   @return [#instrument]
  # @!attribute [rw] use_netgroups
  #   @return [Boolean]
  attr_accessor(*ATTRIBUTES)

  # @param [#to_hash] config
  # @raise [ArgumentError] if config is not a Hash
  # @raise [ConfigError] if config contains invalid keys
  def initialize(config)
    raise ArgumentError unless config.respond_to?(:to_hash)

    config = validate(convert(config))
    ATTRIBUTES.each do |attr|
      instance_variable_set(:"@#{attr}", config[attr])
    end
  end

  private

  # @param [#to_hash] config
  # @return [Hash]
  def convert(config)
    Hash[
      config.to_hash.map do |key, val|
        key = key.to_sym if key.respond_to?(:to_sym)

        if val && [:encryption, :server_type, :method].include?(key)
          val = val.is_a?(Hash) ? convert(val) : val.to_sym
        end

        [key, val]
      end
    ]
  end

  # @param [Hash] config
  def check_missing_keys(config)
    missing_keys = ATTRIBUTES - config.keys
    raise ConfigError, "missing configuration for keys: #{missing_keys.join(',')}" unless missing_keys.empty?
  end

  # @param [Hash] config
  def check_unknown_keys(config)
    unknown_keys = config.keys - ATTRIBUTES
    raise ConfigError, "unknown configuration keys: #{unknown_keys.join(',')}" unless unknown_keys.empty?
  end

  # @param [Hash] config
  def check_required_keys(config)
    [:host, :port, :base_dn, :group_base, :server_type].each do |key|
      raise ConfigError, "config key #{key} has to be set, it was nil" unless config[key]
    end

    [:service_user, :service_pass].each do |key|
      raise ConfigError, "config key #{key} has to be set, it was nil" unless config[:anon_queries] || config[key]
    end
  end

  # @param [Hash] config
  def check_anon_queries_set(config)
    return if [false, true].include?(config[:anon_queries])

    raise ConfigError, "config key anon_queries has to be true or false but was #{config[:anon_queries]}"
  end

  # @param [Hash] config
  def check_server_type(config)
    return if [:posix, :active_directory, :free_ipa].include?(config[:server_type])

    raise ConfigError,
          "config key server_type has to be :active_directory, :posix, :free_ipa but was #{config[:server_type]}"
  end

  # @param [Hash] config
  # @return [Hash]
  # @raise [ConfigError] if config contains invalid keys
  def validate(config)
    config = DEFAULT_CONFIG.merge(config)
    config[:group_base] = config[:base_dn] if !config[:group_base] || config[:group_base].empty?

    check_server_type(config)
    check_missing_keys(config)
    check_unknown_keys(config)
    check_required_keys(config)
    check_anon_queries_set(config)

    config
  end

  class ConfigError < LdapFluff::Error
  end
end
