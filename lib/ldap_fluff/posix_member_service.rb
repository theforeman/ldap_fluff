require 'net/ldap'

class LdapFluff::Posix::MemberService

  attr_accessor :ldap

  def initialize(ldap,group_base)
    @ldap = ldap
    @group_base = group_base
  end

  # return an ldap user with groups attached
  # note : this method is not particularly fast for large ldap systems
  def find_user(uid)
    groups = []
    puts "Expecting #{name_filter(uid)} : #{@group_base}"
    @ldap.search(:filter => name_filter(uid), :base => @group_base) do |entry|
      groups << entry[:cn][0]
    end
    LdapFluff::Posix::Member.new(groups)
  end

  def times_in_groups(uid, gids, all)
    matches = 0
    filters = []
    gids.each do |cn|
      filters << group_filter(cn)
    end
    group_filters = merge_filters(group_filters,all)
    filter = name_filter(uid) & filters
    @ldap.search(:base => @group_base, :filter => filter).size
  end

  def name_filter(uid)
    Net::LDAP::Filter.eq("memberUid",uid)
  end

  def group_filter(cn)
    Net::LDAP::Filter.eq("cn", cn)
  end
end
