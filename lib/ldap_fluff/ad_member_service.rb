# frozen_string_literal: true

# Naughty bits of active directory LDAP queries
class LdapFluff::ActiveDirectory::MemberService < LdapFluff::GenericMemberService
  # @param [Net::LDAP] ldap
  # @param [Config] config
  def initialize(ldap, config)
    config.instance_variable_set(:@attr_login, 'samaccountname') unless config.attr_login
    super
  end

  # get a list of LDAP groups for a given user in active directory, this means a recursive lookup
  # @param [String] uid
  # @return [Array<String>]
  def find_user_groups(uid)
    # @type [Net::LDAP::Entry]
    data = find_user(uid, true)
    groups_from_ldap_data(data)
  end

  private

  # @param [Net::LDAP::Entry] payload
  # @return [Array<String>] the :memberof attrs + parents, recursively
  def groups_from_ldap_data(payload)
    return [] unless payload

    first_level   = payload[:memberof]
    total_groups, = walk_group_ancestry(first_level, first_level)

    get_groups(first_level + total_groups).uniq
  end

  # recursively loop over the parent list
  # @param [Array<String>] group_dns
  # @param [Array<String>] known_groups
  # @return [Array<Array<String>>]
  def walk_group_ancestry(group_dns = [], known_groups = [], set = [])
    group_dns.each do |group_dn|
      groups = find_parent_groups(group_dn)
      next unless groups

      groups       -= known_groups
      known_groups += groups
      next_level,   = walk_group_ancestry(groups, known_groups) # new_known_groups

      set          += next_level + groups
      known_groups += next_level
    end

    [set, known_groups]
  end

  # @param [String] group_dn
  # @return [Array<String>]
  def find_parent_groups(group_dn)
    search = ldap.search(base: group_dn, scope: Net::LDAP::SearchScope_BaseObject, attributes: ['memberof'])

    search = search.first if search
    search ? search[:memberof] : nil
  end

  class UIDNotFoundException < LdapFluff::Error
  end

  class GIDNotFoundException < LdapFluff::Error
  end
end
