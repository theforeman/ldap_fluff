class LdapFluff::Posix < LdapFluff::Generic

  def initialize(config = {})
    @base           = config.base_dn
    super
  end

  def bind?(uid = nil, password = nil)
    @ldap.bind_as(:filter => "(uid=#{uid})", :password => password)
  end

  # returns whether a user is a member of ALL or ANY particular groups
  # note: this method is much faster than groups_for_uid
  #
  # gids should be an array of group common names
  #
  # returns true if owner is in ALL of the groups if all=true, otherwise
  # returns true if owner is in ANY of the groups
  def is_in_groups(uid, gids = [], all = true)
    (gids.empty? || @member_service.times_in_groups(uid, gids, all) > 0)
  end

  private

  def users_from_search_results(search, method)
    # To find groups in standard LDAP without group membership attributes
    # we have to look for OUs or posixGroups within the current group scope,
    # i.e: cn=ldapusers,ou=groups,dc=example,dc=com -> cn=myusers,cn=ldapusers,ou=gr...

    groups = @ldap.search(:base   => search.dn,
                          :filter => Net::LDAP::Filter.eq('objectClass','posixGroup') |
                                     Net::LDAP::Filter.eq('objectClass', 'organizationalunit'))

    members = groups.map { |group| group.send(method) }.flatten.uniq

    if method == :memberuid
      members
    else
      @member_service.get_logins(members)
    end
  end
end
