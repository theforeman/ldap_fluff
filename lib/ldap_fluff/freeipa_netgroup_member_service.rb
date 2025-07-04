require 'net/ldap'

class LdapFluff::FreeIPA::NetgroupMemberService < LdapFluff::FreeIPA::MemberService
  def find_user_groups(uid)
    groups = []
    success = @ldap.search(:filter => Net::LDAP::Filter.eq('objectClass', 'nisNetgroup'), :base => @group_base, :return_result => false) do |entry|
      members = get_netgroup_users(entry[:nisnetgrouptriple])
      groups << entry[:cn][0] if members.include? uid
    end
    unless success
      raise Net::LDAP::Error, @ldap.get_operation_result[:error_message].to_s
    end
    groups
  end
end
