require 'net/ldap'

class LdapFluff::FreeIPA::NetgroupMemberService < LdapFluff::FreeIPA::MemberService
  def find_user_groups(uid)
    groups = []
    @ldap.search(:filter => Net::LDAP::Filter.eq('objectClass', 'nisNetgroup'), :base => @group_base).each do |entry|
      members = get_netgroup_users(entry[:nisnetgrouptriple])
      groups << entry[:cn][0] if members.include? uid
    end
    groups
  end
end
