require 'net/ldap'

# Naughty bits of active directory ldap queries
class LdapFluff::ActiveDirectory::MemberService < LdapFluff::GenericMemberService

  def initialize(ldap, config)
    @attr_login = (config.attr_login || 'samaccountname')
    super
  end

  # get a list [] of ldap groups for a given user
  # in active directory, this means a recursive lookup
  def find_user_groups(uid)
    data = find_user(uid)
    _groups_from_ldap_data(data.first)
  end

  # return the :memberof attrs + parents, recursively
  def _groups_from_ldap_data(payload)
    data = []
    if !payload.nil?
      first_level  = payload[:memberof]
      total_groups = _walk_group_ancestry(first_level)
      data         = (get_groups(first_level + total_groups)).uniq
    end
    data
  end

  # recursively loop over the parent list
  def _walk_group_ancestry(group_dns = [])
    set = []
    group_dns.each do |group_dn|
      search = @ldap.search(:base => group_dn, :scope => Net::LDAP::SearchScope_BaseObject)
      if !search.nil? && !search.first.nil?
        group = search.first
        set  += group[:memberof]
        set  += _walk_group_ancestry(set)
      end
    end
    set
  end

  def class_filter
    Net::LDAP::Filter.eq("objectclass", "group")
  end

  class UIDNotFoundException < LdapFluff::Error
  end

  class GIDNotFoundException < LdapFluff::Error
  end
end
