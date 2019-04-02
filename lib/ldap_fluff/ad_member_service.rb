require 'net/ldap'

# Naughty bits of active directory ldap queries
class LdapFluff::ActiveDirectory::MemberService < LdapFluff::GenericMemberService

  def initialize(ldap, config)
    @attr_login = (config.attr_login || 'samaccountname')
    super
  end

  def find_group(gid)
    group = @ldap.search(:filter => group_filter(gid), :base => @group_base, :attributes => ['*','primaryGroupToken'])
    raise self.class::GIDNotFoundException if (group.nil? || group.empty?)
    group
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
      first_level         = payload[:memberof]
      normal_groups, _    = _walk_group_ancestry(first_level, first_level)
      # In AD, a user's primary group is not included in the memberOf list, and must be handled separately.
      #   By default, a new user's primary group is 'Domain Users'
      primary_groups      = []
      primary_first_level = []
      if !payload[:primarygroupid].nil?
        domain_sid          = _get_sid_string(payload[:objectsid].first).split('-')[0..-2].join('-')
        primary_sid         = domain_sid + '-' + payload[:primarygroupid].first
        primary_group       = @ldap.search(:filter => Net::LDAP::Filter.eq('objectsid', primary_sid), :base => @group_base, :attributes => ['memberof']).first
        primary_first_level = primary_group[:dn]
        primary_groups, _   = _walk_group_ancestry(primary_first_level, primary_first_level)
      end
      data              = (get_groups(first_level + normal_groups + primary_first_level + primary_groups)).uniq
    end
    data
  end

  # recursively loop over the parent list
  def _walk_group_ancestry(group_dns = [], known_groups = [])
    set = []
    group_dns.each do |group_dn|
      search = @ldap.search(:base => group_dn, :scope => Net::LDAP::SearchScope_BaseObject, :attributes => ['memberof'])
      if !search.nil? && !search.first.nil?
        groups                       = search.first[:memberof] - known_groups
        known_groups                += groups
        next_level, new_known_groups = _walk_group_ancestry(groups, known_groups)
        set                         += next_level
        set                         += groups
        known_groups                += next_level
      end
    end
    [set, known_groups]
  end

  def _get_sid_string(sid_bin)
    sid = []
 
    # Byte 1: SID structure revision number (always 1 so far...)
    sid << sid_bin[0].unpack("H2").first.to_i
 
    # Skip byte 2
    # Bytes 3-8: Identifier Authority
    sid << sid_bin[2,6].unpack("H*").first.to_i

    # Remaining bytes: list of unsigned, 32-bit, little-endian ints
    sid += sid_bin.unpack("@8V*")

    # Put it all together.
    "S-" + sid.join('-')
  end

  def class_filter
    Net::LDAP::Filter.eq("objectclass", "group")
  end

  class UIDNotFoundException < LdapFluff::Error
  end

  class GIDNotFoundException < LdapFluff::Error
  end
end
