require 'net/ldap'

# Naughty bits of active directory ldap queries
class LdapFluff::ActiveDirectory::MemberService < LdapFluff::GenericMemberService
  def initialize(ldap, config)
    @attr_login = (config.attr_login || 'samaccountname')
    super
  end

  # get a list [] of ldap groups for a given user
  # try to use msds-memberOfTransitive if it is supported, otherwise do a recursive loop
  def find_user_groups(uid)
    user_data = find_user(uid).first

    if _get_domain_func_level >= 6
      user_dn = user_data[:distinguishedname].first
      search = @ldap.search(:base => user_dn, :scope => Net::LDAP::SearchScope_BaseObject, :attributes => ['msds-memberOfTransitive'])
      if !search.nil? && !search.first.nil?
        return get_groups(search.first['msds-memberoftransitive'])
      end
    end

    # Fall back to recursive lookup
    _groups_from_ldap_data(user_data)
  end

  # return the domain functionality level, default to 0
  def _get_domain_func_level
    return @domain_functionality unless @domain_functionality.nil?

    @domain_functionality = 0

    search = @ldap.search(:base => "", :scope => Net::LDAP::SearchScope_BaseObject, :attributes => ['domainFunctionality'])
    if !search.nil? && !search.first.nil?
      @domain_functionality = search.first[:domainfunctionality].first.to_i
    end

    @domain_functionality
  end

  # return the :memberof attrs + parents, recursively
  def _groups_from_ldap_data(payload)
    data = []
    unless payload.nil?
      first_level = payload[:memberof]
      total_groups, = _walk_group_ancestry(first_level, first_level)
      data = get_groups(first_level + total_groups).uniq
    end
    data
  end

  # recursively loop over the parent list
  def _walk_group_ancestry(group_dns = [], known_groups = [])
    set = []
    group_dns.each do |group_dn|
      search = @ldap.search(:base => group_dn, :scope => Net::LDAP::SearchScope_BaseObject, :attributes => ['memberof'])
      next unless !search.nil? && !search.first.nil?
      groups = search.first[:memberof] - known_groups
      known_groups                += groups
      next_level, new_known_groups = _walk_group_ancestry(groups, known_groups)
      set                         += next_level
      set                         += groups
      known_groups                += next_level
    end
    [set, known_groups]
  end

  def class_filter
    Net::LDAP::Filter.eq("objectclass", "group")
  end

  class UIDNotFoundException < LdapFluff::Error
  end

  class GIDNotFoundException < LdapFluff::Error
  end
end
