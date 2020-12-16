class LdapFluff::Posix < LdapFluff::Generic
  def bind?(uid = nil, password = nil, opts = {})
    unless uid.include?(',') || opts[:search] == false
      service_bind
      user = @member_service.find_user(uid)
      uid = user.first.dn if user&.first
    end
    @ldap.auth(uid, password)
    @ldap.bind
  end

  private

  def users_from_search_results(search, method)
    # To find groups in standard LDAP without group membership attributes
    # we have to look for OUs or posixGroups within the current group scope,
    # i.e: cn=ldapusers,ou=groups,dc=example,dc=com -> cn=myusers,cn=ldapusers,ou=gr...

    filter = if @use_netgroups
               Net::LDAP::Filter.eq('objectClass', 'nisNetgroup')
             else
               Net::LDAP::Filter.eq('objectClass', 'posixGroup') |
                 Net::LDAP::Filter.eq('objectClass', 'organizationalunit') |
                 Net::LDAP::Filter.eq('objectClass', 'groupOfUniqueNames') |
                 Net::LDAP::Filter.eq('objectClass', 'groupOfNames')
             end
    groups = @ldap.search(:base => search.dn, :filter => filter)
    members = groups.map { |group| group.send(method) }.flatten.uniq

    if method == :memberuid
      members
    elsif method == :nisnetgrouptriple
      @member_service.get_netgroup_users(members)
    else
      @member_service.get_logins(members)
    end
  end
end
