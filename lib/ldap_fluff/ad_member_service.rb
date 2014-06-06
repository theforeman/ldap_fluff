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
      first_level  = get_groups(payload[:memberof])
      total_groups = _walk_group_ancestry(first_level)
      data         = (first_level + total_groups).uniq
    end
    data
  end

  # recursively loop over the parent list
  def _walk_group_ancestry(gids = [])
    set = []
    gids.each do |g|
      filter = group_filter(g) & class_filter
      search = @ldap.search(:filter => filter, :base => @group_base)
      if !search.nil? && !search.first.nil?
        group = search.first
        set  += get_groups(group[:memberof])
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
