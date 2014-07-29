require 'rubygems'
require 'net/ldap'

class LdapFluff
  attr_accessor :ldap

  def initialize(config = {})
    config = LdapFluff::Config.new(config)
    case config.server_type
    when :posix
      @ldap = Posix.new(config)
    when :active_directory
      @ldap = ActiveDirectory.new(config)
    when :free_ipa
      @ldap = FreeIPA.new(config)
    else
      raise 'unknown server_type'
    end
  end

  def authenticate?(uid, password)
    if password.nil? || password.empty?
      false
    else
      !!@ldap.bind?(uid, password)
    end
  end

  def test
    @ldap.ldap.open {}
  end

  # return a list[] of users for a given gid
  def user_list(gid)
    @ldap.users_for_gid(gid)
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

  # return ldap entry
  def find_user(uid)
    @ldap.member_service.find_user(uid)
  end

  # return ldap entry
  def find_group(gid)
    @ldap.member_service.find_group(gid)
  end
end
