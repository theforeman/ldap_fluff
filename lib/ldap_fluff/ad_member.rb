require 'net-ldap'

class LdapFluff::ActiveDirectory::Member
  attr_accessor :ldap, :data

  def initialize(ldap, data)
    @ldap, @data = ldap, data
  end

  # return the :memberof attrs + parents, recursively
  def self.groups
    total_groups = Group.group_names_from_cn(@data[:memberof])
    first_level = total_groups
    first_level.each do |g|
      total_groups += Group.new(@ldap,g,@group_base).complete_walk
    end
    total_groups.uniq
  end


  class Group
    attr_accessor :ldap

    def initialize(ldap, gid, gbase)
      @class_filter = Net::LDAP::Filter.eq("objectclass","group")
      @search_filter = group_filter(gid) & @class_filter
      @gid = gid
    end

    def group_filter(gid)
      Net::LDAP::Filter.eq("cn", gid)
    end

    def complete_walk
      group_parents([@gid])
    end

    # recursively loop over the parent list
    def group_parents(gids=[])
      set = []
      gids.each do |g|
        filter = group_filter(gid) & @class_filter
        group = @ldap.search(:filter => filter, :base => @gbase).first
        begin
          set += Group.group_names_from_cn(group[:memberof])
        rescue Exception
          return []
        end
        set += parent_loop(set)
      end
      set
    end

    # extract the group names from the LDAP style response,
    # return string will be something like
    # CN=bros,OU=bropeeps,DC=jomara,DC=redhat,DC=com
    #
    # AD group proc from
    # http://erniemiller.org/2008/04/04/simplified-active-directory-authentication/
    #
    # I think we would normally want to just do the collect at the end,
    # but we need the individual names for recursive queries
    def self.group_names_from_cn(grouplist)
      p = Proc.new { |g| g.sub(/.*?CN=(.*?),.*/, '\1') }
      grouplist.collect(&p)
    end

  end
end
