# frozen_string_literal: true

# handles the naughty bits of POSIX LDAP
class LdapFluff::Posix::NetgroupMemberService < LdapFluff::Posix::MemberService
  # @param [String] uid
  # @return [Array<String>] list of group CNs for a user
  def find_user_groups(uid)
    groups = []
    @ldap.search(filter: Net::LDAP::Filter.eq('objectClass', 'nisNetgroup'), base: @group_base).each do |entry|
      members = get_netgroup_users(entry[:nisnetgrouptriple])
      groups << entry[:cn][0] if members.include? uid
    end

    groups
  end
end
