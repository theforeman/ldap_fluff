# Copyright 2012 Red Hat, Inc.
#
# This software is licensed to you under the GNU General Public
# License as published by the Free Software Foundation; either version
# 2 of the License (GPLv2) or (at your option) any later version.
# There is NO WARRANTY for this software, express or implied,
# including the implied warranties of MERCHANTABILITY,
# NON-INFRINGEMENT, or FITNESS FOR A PARTICULAR PURPOSE. You should
# have received a copy of GPLv2 along with this software; if not, see
# http://www.gnu.org/licenses/old-licenses/gpl-2.0.txt.

class LdapConnection::Posix
  def initialize(config={})
    config ||= LdapFluff::Config.instance
    @ldap = Net::LDAP.new :host => config.host
                         :base => config.base_dn
                         :port => config.port
                         :encryption => config.encryption
    @group_base = config.group_base
    @group_base ||= config.base
  end

  def bind?(uid=nil, password=nil)
    @ldap.auth "uid=#{uid},#{@base}", password
    @ldap.bind
  end

  # returns a list of ldap groups to which a user belongs
  # note : this method is not particularly fast for large ldap systems
  def groups_for_uid(uid)
    filter = Net::LDAP::Filter.eq("memberUid", uid)
    # group base name must be preconfigured
    treebase = @group_base
    groups = []
    # groups filtering will work w/ group common names
    @ldap.search(:base => treebase, :filter => filter) do |entry|
      groups << entry[:cn][0]
    end
    groups
  end

  # returns whether a user is a member of ALL or ANY particular groups
  # note: this method is much faster than groups_for_uid
  #
  # gids should be an array of group common names
  #
  # returns true if owner is in ALL of the groups if all=true, otherwise
  # returns true if owner is in ANY of the groups
  def is_in_groups(uid, gids = [], all=false)
    return true if gids.empty?
    filter = Net::LDAP::Filter.eq("memberUid", uid)
    treebase = @group_base
    raise _("group_base was not set in katello.yml") if not treebase
    group_filters = []
    matches = 0
    # we need a new filter for each group cn
    gids.each do |group_cn|
      group_filters << Net::LDAP::Filter.eq("cn", group_cn)
    end
    group_filters = merge_filters(group_filters, all)
    # AND the set of group filters w/ base filter
    filter = filter & group_filters
    @ldap.search(:base => treebase, :filter => filter) do |entry|
      matches = matches + 1
    end

    return matches > 0
  end

end
