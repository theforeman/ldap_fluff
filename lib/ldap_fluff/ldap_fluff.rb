require 'net/ldap'

class LdapFluff
  class ConfigError < StandardError; end

  attr_accessor :ldap

  def initialize(config=nil)
    config ||= LdapFluff::Config.instance
    type = config.server_type
    if type.respond_to? :to_sym
      if type.to_sym == :posix
        @ldap = Posix.new(config)
      elsif type.to_sym == :active_directory
        @ldap = ActiveDirectory.new(config)
      elsif type.to_sym == :free_ipa
        @ldap = FreeIPA.new(config)
      else
        raise ConfigError, "Unsupported connection type. Supported types = :active_directory, :posix, :free_ipa"
      end
    end
  end

  # return true if the user password combination
  # authenticates the user, otherwise false
  def authenticate?(uid, password)
    if password.nil? || password.empty?
      # protect against passwordless auth from ldap server
      return false
    else
      @ldap.bind? uid, password
    end
  end

  # return a list[] of groups for a given uid
  def group_list(uid)
    @ldap.groups_for_uid(uid)
  end

  # return true if a user is in all of the groups
  # in grouplist
  def is_in_groups?(uid, grouplist)
    @ldap.is_in_groups(uid, grouplist, true)
  end

end
