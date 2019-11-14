# frozen_string_literal: true

class LdapFluff::Posix < LdapFluff::Generic
  # @param [String] uid
  # @param [String] password
  # @param [Hash] opts
  # @return [Boolean]
  def bind?(uid = nil, password = nil, opts = {})
    if opts[:search] != false && uid && !uid.include?(',')
      service_bind
      user = member_service.find_user(uid, true)

      uid = user.dn if user
    end

    super(uid, password)
  end

  private

  # @return [Net::LDAP::Filter]
  def group_class_filter
    if config.use_netgroups
      Net::LDAP::Filter.eq('objectClass', 'nisNetgroup')
    else
      Net::LDAP::Filter.eq('objectClass', 'posixGroup') |
        Net::LDAP::Filter.eq('objectClass', 'organizationalunit') |
        Net::LDAP::Filter.eq('objectClass', 'groupOfUniqueNames') |
        Net::LDAP::Filter.eq('objectClass', 'groupOfNames')
    end
  end

  # To find groups in standard LDAP without group membership attributes
  # we have to look for OUs or posixGroups within the current group scope,
  # i.e: cn=ldapusers,ou=groups,dc=example,dc=com -> cn=myusers,cn=ldapusers,ou=gr...
  #
  # @param [Net::LDAP::Entry] search
  # @param [Symbol] method
  # @return [Array<String>]
  def users_from_search_results(search, method)
    groups = ldap.search(base: search.dn, filter: group_class_filter)
    members = groups.map { |group| group.send(method) }.flatten.uniq

    case method
    when :memberuid
      # memberuid contains an array ['user1','user2'], no need to parse it
      members
    when :nisnetgrouptriple
      member_service.get_netgroup_users(members)
    else
      member_service.get_logins(members)
    end
  end
end
