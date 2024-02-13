require 'net/ldap'

# handles the naughty bits of posix ldap
class LdapFluff::Posix::MemberService < LdapFluff::GenericMemberService
  def initialize(ldap, config)
    @attr_login = (config.attr_login || 'memberuid')
    super
  end

  def find_user(uid, base_dn = @base)
    user = @ldap.search(:filter => name_filter(uid), :base => base_dn)
    raise UIDNotFoundException if (user.nil? || user.empty?)
    user
  end

  # return an ldap user with groups attached
  # note : this method is not particularly fast for large ldap systems
  # This group will check all the groups and will match the user. MemberOf plugin
  # it's not required for this operation, once this plugin it's optional in ldap.
  def find_user_groups(uid)
    groups = []

    search_filter = Net::LDAP::Filter.eq('objectClass', 'groupOfNames')
    results_attr = ["cn", "member"]

    ldap.search(:filter => search_filter, :attributes => results_attr).each do |grp_info|

      grp_info[:member].each do |login|
        only_uid = login.split(',')[0].split('=')[1]

        if only_uid.include?(uid)
          groups << grp_info[:cn]
        end
      end
    end

    if groups.length > 0
      groups.flatten!
    else
      groups = []
    end
  end




  def times_in_groups(uid, gids, all)
    filters = []
    gids.each do |cn|
      filters << group_filter(cn)
    end
    group_filters = merge_filters(filters, all)
    filter        = name_filter(uid) & group_filters
    @ldap.search(:base => @group_base, :filter => filter).size
  end

  # AND or OR all of the filters together
  def merge_filters(filters = [], all = false)
    if !filters.nil? && filters.size >= 1
      filter = filters[0]
      filters[1..(filters.size - 1)].each do |gfilter|
        filter = (all ? filter & gfilter : filter | gfilter)
      end
      filter
    end
  end

  class UIDNotFoundException < LdapFluff::Error
  end

  class GIDNotFoundException < LdapFluff::Error
  end
end
