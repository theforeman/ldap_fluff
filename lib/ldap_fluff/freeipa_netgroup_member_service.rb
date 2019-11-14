# frozen_string_literal: true

class LdapFluff::FreeIPA::NetgroupMemberService < LdapFluff::FreeIPA::MemberService
  # @param [String] uid
  # @return [Array<String>]
  def find_user_groups(uid)
    groups = ldap.search(filter: Net::LDAP::Filter.eq('objectClass', 'nisNetgroup'), base: config.group_base)
    return [] unless groups

    groups.map do |entry|
      members = get_netgroup_users(entry[:nisnetgrouptriple])

      members.include?(uid) ? entry[:cn].first : nil
    end.compact
  end
end
