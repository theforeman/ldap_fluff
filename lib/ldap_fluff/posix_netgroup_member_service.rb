require 'net/ldap'

# handles the naughty bits of posix ldap
class LdapFluff::Posix::NetgroupMemberService < LdapFluff::Posix::MemberService

  # return list of group CNs for a user
  def find_user_groups(uid)
    groups = []
    @ldap.search(:filter => Net::LDAP::Filter.eq('objectClass', 'nisNetgroup'), :base => @group_base).each do |entry|
      members = get_netgroup_users(entry[:nisnetgrouptriple])
      groups << entry[:cn][0] if members.include? uid
    end
    groups
  end

end
