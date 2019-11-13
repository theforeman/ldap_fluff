# frozen_string_literal: true

require 'net/ldap'

require 'ldap_fluff/error'
require 'ldap_fluff/config'
require 'ldap_fluff/generic'
require 'ldap_fluff/generic_member_service'
require 'ldap_fluff/active_directory'
require 'ldap_fluff/ad_member_service'
require 'ldap_fluff/posix'
require 'ldap_fluff/posix_member_service'
require 'ldap_fluff/posix_netgroup_member_service'
require 'ldap_fluff/freeipa'
require 'ldap_fluff/freeipa_member_service'
require 'ldap_fluff/freeipa_netgroup_member_service'

class LdapFluff
  # @!attribute [rw] ldap
  #   @return [Generic]
  # @!attribute [rw] instrumentation_service
  #   @return [#instrument]
  attr_accessor :ldap, :instrumentation_service

  def initialize(config = {})
    config = LdapFluff::Config.new(config)

    @ldap =
      case config.server_type
      when :posix
        Posix.new(config)
      when :active_directory
        ActiveDirectory.new(config)
      when :free_ipa
        FreeIPA.new(config)
      else
        raise 'unknown server_type'
      end

    @instrumentation_service = config.instrumentation_service
  end

  # @param [String] uid
  # @param [String] password
  # @return [Boolean]
  def authenticate?(uid, password)
    instrument('authenticate.ldap_fluff', uid: uid) do |payload|
      if password.nil? || password.empty?
        false
      else
        !!@ldap.bind?(uid, password)
      end
    end
  end

  def test
    instrument('test.ldap_fluff') do |payload|
      @ldap.ldap.open {}
    end
  end

  # @param [String] gid
  # @return [Array<String>] a list of users for a given gid
  def user_list(gid)
    instrument('user_list.ldap_fluff', gid: gid) do |payload|
      @ldap.users_for_gid(gid)
    end
  end

  # @param [String] uid
  # @return [Array<String>] a list of groups for a given uid
  def group_list(uid)
    instrument('group_list.ldap_fluff', uid: uid) do |payload|
      @ldap.groups_for_uid(uid)
    end
  end

  # @param [String] uid
  # @return [Boolean] true if a user is in all of the groups in grouplist
  def is_in_groups?(uid, grouplist)
    instrument('is_in_groups?.ldap_fluff', uid: uid, grouplist: grouplist) do |payload|
      @ldap.is_in_groups(uid, grouplist, true)
    end
  end

  # @param [String] uid
  # @return [Boolean] true if uid exists
  def valid_user?(uid)
    instrument('valid_user?.ldap_fluff', uid: uid) do |payload|
      @ldap.user_exists? uid
    end
  end

  # @param [String] gid
  # @return [Boolean] true if group exists
  def valid_group?(gid)
    instrument('valid_group?.ldap_fluff', gid: gid) do |payload|
      @ldap.group_exists? gid
    end
  end

  # @param [String] uid
  # @return [Array, Net::LDAP::Entry]
  def find_user(uid)
    instrument('find_user.ldap_fluff', uid: uid) do |payload|
      @ldap.member_service.find_user(uid)
    end
  end

  # @param [String] gid
  # @return [Array, Net::LDAP::Entry]
  def find_group(gid)
    instrument('find_group.ldap_fluff', gid: gid) do |payload|
      @ldap.member_service.find_group(gid)
    end
  end

  private

  # @param [String] event
  # @param [Hash] payload
  # @yieldreturn [Hash]
  def instrument(event, payload = {})
    payload = payload ? payload.dup : {}

    if instrumentation_service
      instrumentation_service.instrument(event, payload) do |payload|
        payload[:result] = yield(payload) if block_given?
      end
    elsif block_given?
      yield(payload)
    end
  end
end
