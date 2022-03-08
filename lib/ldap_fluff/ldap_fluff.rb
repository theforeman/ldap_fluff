require 'rubygems'
require 'net/ldap'

class LdapFluff
  attr_accessor :ldap, :instrumentation_service

  def initialize(config = {})
    config = LdapFluff::Config.new(config)
    case config.server_type
    when :posix
      @ldap = Posix.new(config)
    when :active_directory
      @ldap = ActiveDirectory.new(config)
    when :free_ipa
      @ldap = FreeIPA.new(config)
    when :netiq
      @ldap = NetIQ.new(config)
    else
      raise 'unknown server_type'
    end
    @instrumentation_service = config.instrumentation_service
  end

  def authenticate?(uid, password)
    instrument('authenticate.ldap_fluff', :uid => uid) do |_payload|
      if password.nil? || password.empty?
        false
      else
        !!@ldap.bind?(uid, password)
      end
    end
  end

  def test
    instrument('test.ldap_fluff') do |_payload|
      @ldap.ldap.open {}
    end
  end

  # return a list[] of users for a given gid
  def user_list(gid)
    instrument('user_list.ldap_fluff', :gid => gid) do |_payload|
      @ldap.users_for_gid(gid)
    end
  end

  # return a list[] of groups for a given uid
  def group_list(uid)
    instrument('group_list.ldap_fluff', :uid => uid) do |_payload|
      @ldap.groups_for_uid(uid)
    end
  end

  # return true if a user is in all of the groups
  # in grouplist
  def is_in_groups?(uid, grouplist)
    instrument('is_in_groups?.ldap_fluff', :uid => uid, :grouplist => grouplist) do |_payload|
      @ldap.is_in_groups(uid, grouplist, true)
    end
  end

  # return true if uid exists
  def valid_user?(uid)
    instrument('valid_user?.ldap_fluff', :uid => uid) do |_payload|
      @ldap.user_exists? uid
    end
  end

  # return true if group exists
  def valid_group?(gid)
    instrument('valid_group?.ldap_fluff', :gid => gid) do |_payload|
      @ldap.group_exists? gid
    end
  end

  # return ldap entry
  def find_user(uid)
    instrument('find_user.ldap_fluff', :uid => uid) do |_payload|
      @ldap.member_service.find_user(uid)
    end
  end

  # return ldap entry
  def find_group(gid)
    instrument('find_group.ldap_fluff', :gid => gid) do |_payload|
      @ldap.member_service.find_group(gid)
    end
  end

  private

  def instrument(event, payload = {})
    payload = (payload || {}).dup
    if instrumentation_service
      instrumentation_service.instrument(event, payload) do |payload|
        payload[:result] = yield(payload) if block_given?
      end
    else
      yield(payload) if block_given?
    end
  end
end
