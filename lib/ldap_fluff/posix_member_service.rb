# frozen_string_literal: true

# handles the naughty bits of POSIX LDAP
class LdapFluff::Posix::MemberService < LdapFluff::GenericMemberService
  # @param [Net::LDAP] ldap
  # @param [LdapFluff::Config] config
  def initialize(ldap, config)
    config.attr_login ||= 'uid'
    config.attr_member ||= 'memberuid'
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
    groups = ldap.search(filter: group_filter(uid, config.attr_member), base: config.group_base)
    return [] unless groups

    groups.map { |entry| entry[:cn].first }
  end

  class UIDNotFoundException < LdapFluff::Error
  end

  class GIDNotFoundException < LdapFluff::Error
  end
end
