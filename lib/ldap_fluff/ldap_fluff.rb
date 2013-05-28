require 'rubygems'
require 'net/ldap'

class LdapFluff
  class ConfigError < StandardError
  end

  attr_accessor :ldap

  def initialize(config = {})
    config = LdapFluff::Config.new config
    case config.server_type
    when :posix
      @ldap = Posix.new(config)
    when :active_directory
      @ldap = ActiveDirectory.new(config)
    when :free_ipa
      @ldap = FreeIPA.new(config)
    else
      raise ConfigError, "Unsupported connection type #{config.server_type.inspect}. Supported types = :active_directory, :posix, :free_ipa"
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

  # return true if uid exists
  def valid_user?(uid)
    @ldap.user_exists? uid
  end

  # return true if group exists
  def valid_group?(gid)
    @ldap.group_exists? gid
  end

end
