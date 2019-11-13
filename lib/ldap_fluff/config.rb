# frozen_string_literal: true

class LdapFluff::Config
  ATTRIBUTES = [
    :host, :port, :encryption, :base_dn, :group_base, :server_type, :service_user,
    :service_pass, :anon_queries, :attr_login, :search_filter,
    :instrumentation_service, :use_netgroups
  ].freeze

  DEFAULT_CONFIG = {
    port: 389,
    encryption: nil,
    base_dn: 'dc=company,dc=com',
    group_base: 'dc=company,dc=com',
    server_type: :free_ipa,
    anon_queries: false,
    instrumentation_service: nil,
    use_netgroups: false
  }.freeze

  # @!attribute [r] host
  #   @return [String]
  # @!attribute [r] port
  #   @return [Integer]
  # @!attribute [r] encryption
  #   @return [Symbol, Hash]
  # @!attribute [r] base_dn
  #   @return [String]
  # @!attribute [r] group_base
  #   @return [String]
  # @!attribute [r] server_type
  #   @return [Symbol]
  # @!attribute [r] service_user
  #   @return [String]
  # @!attribute [r] service_pass
  #   @return [String]
  # @!attribute [r] anon_queries
  #   @return [Boolean]
  # @!attribute [r] attr_login
  #   @return [String]
  # @!attribute [r] search_filter
  #   @return [String]
  # @!attribute [r] instrumentation_service
  #   @return [#instrument]
  # @!attribute [r] use_netgroups
  #   @return [Boolean]
  attr_reader(*ATTRIBUTES)

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
  def missing_keys?(config)
    missing_keys = ATTRIBUTES - config.keys
    raise ConfigError, "missing configuration for keys: #{missing_keys.join(',')}" unless missing_keys.empty?
  end

  # @param [Hash] config
  def unknown_keys?(config)
    unknown_keys = config.keys - ATTRIBUTES
    raise ConfigError, "unknown configuration keys: #{unknown_keys.join(',')}" unless unknown_keys.empty?
  end

  # @param [Hash] config
  def all_required_keys?(config)
    [:host, :port, :base_dn, :group_base, :server_type].each do |key|
      raise ConfigError, "config key #{key} has to be set, it was nil" unless config[key]
    end

    [:service_user, :service_pass].each do |key|
      raise ConfigError, "config key #{key} has to be set, it was nil" unless config[:anon_queries] || config[key]
    end
  end

  # @param [Hash] config
  def anon_queries_set?(config)
    return if [false, true].include?(config[:anon_queries])

    raise ConfigError, "config key anon_queries has to be true or false but was #{config[:anon_queries]}"
  end

  # @param [Hash] config
  def correct_server_type?(config)
    return if [:posix, :active_directory, :free_ipa].include?(config[:server_type])

    raise ConfigError,
          "config key server_type has to be :active_directory, :posix, :free_ipa but was #{config[:server_type]}"
  end

  # @param [Hash] config
  # @return [Hash]
  # @raise [ConfigError] if config contains invalid keys
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
