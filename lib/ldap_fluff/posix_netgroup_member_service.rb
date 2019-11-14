# frozen_string_literal: true

# handles the naughty bits of POSIX LDAP
class LdapFluff::Posix::NetgroupMemberService < LdapFluff::Posix::MemberService
  # @param [String] uid
  # @return [Array<String>] list of group CNs for a user
  def find_user_groups(uid)
    groups = ldap.search(filter: Net::LDAP::Filter.eq('objectClass', 'nisNetgroup'), base: config.group_base)
    return [] unless groups

    groups.map do |entry|
      members = get_netgroup_users(entry[:nisnetgrouptriple])

      members.include?(uid) ? entry[:cn].first : nil
    end.compact
  end
end
