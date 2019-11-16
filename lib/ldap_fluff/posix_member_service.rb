# frozen_string_literal: true

# handles the naughty bits of POSIX LDAP
class LdapFluff::Posix::MemberService < LdapFluff::GenericMemberService
  # @param [Net::LDAP] ldap
  # @param [LdapFluff::Config] config
  def initialize(ldap, config)
    config.instance_variable_set(:@attr_login, 'memberuid') unless config.attr_login
    super
  end

  # @param [String] uid
  # @return [Array<Net::LDAP::Entry>, Net::LDAP::Entry]
  # @raise [UIDNotFoundException]
  def find_user(uid, only = nil, base_dn = nil)
    if only.is_a?(String)
      base_dn ||= only
      only = nil
    else
      base_dn ||= config.base_dn
    end

    # @type [Array<Net::LDAP::Entry>]
    user = ldap.search(filter: name_filter(uid), base: base_dn)
    raise UIDNotFoundException if !user || user.empty?

    return_one_or_all(user, only)
  end

  # @param [String] uid
  # @return [Array<String>] an LDAP user with groups attached
  # @note this method is not particularly fast for large LDAP systems
  def find_user_groups(uid)
    groups = ldap.search(filter: name_filter(uid), base: config.group_base)
    return [] unless groups

    groups.map { |entry| entry[:cn].first }
  end

  # @param [String] uid
  # @param [Array<String>] gids
  # @deprecated
  def times_in_groups(uid, gids, all = false)
    filters       = gids.map { |cn| group_filter(cn) }
    # AND or OR all of the filters together
    group_filters = filters.reduce(all ? :& : :|)
    filter        = name_filter(uid) & group_filters

    (ldap.search(base: config.group_base, filter: filter) || []).size
  end

  class UIDNotFoundException < LdapFluff::Error
  end

  class GIDNotFoundException < LdapFluff::Error
  end
end
