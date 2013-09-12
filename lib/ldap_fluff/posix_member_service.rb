require 'net/ldap'

# handles the naughty bits of posix ldap
class LdapFluff::Posix::MemberService

  attr_accessor :ldap

  def initialize(ldap, group_base)
    @ldap       = ldap
    @group_base = group_base
  end

  # return an ldap user with groups attached
  # note : this method is not particularly fast for large ldap systems
  def find_user_groups(uid)
    groups = []
    find_user(uid).each do |entry|
      groups << entry[:cn][0]
    end
    groups
  end

  def find_user(uid)
    user = @ldap.search(:filter => name_filter(uid), :base => @group_base)
    raise UIDNotFoundException if (user.nil? || user.empty?)
    user
  end

  def find_group(gid)
    group = @ldap.search(:filter => group_filter(gid), :base => @group_base)
    raise GIDNotFoundException if (group.nil? || group.empty?)
    group
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

  def name_filter(uid)
    Net::LDAP::Filter.eq("memberUid", uid)
  end

  def group_filter(cn)
    Net::LDAP::Filter.eq("cn", cn)
  end

  # AND or OR all of the filters together
  def merge_filters(filters = [], all = false)
    if !filters.nil? && filters.size >= 1
      filter = filters[0]
      filters[1..(filters.size - 1)].each do |gfilter|
        filter = (all ? filter & gfilter : filter | gfilter)
      end
      return filter
    end
  end

  class UIDNotFoundException < StandardError
  end

  class GIDNotFoundException < StandardError
  end

end
