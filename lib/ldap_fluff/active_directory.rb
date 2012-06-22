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

class LdapConnection::ActiveDirectory

  attr_accessor :ldap

  def initialize(config={})
    @ldap = Net::LDAP.new :host => config.host,
                         :base => config.base_dn,
                         :port => config.port
    @group_base = config.group_base
    @group_base ||= config.base
    @ad_domain = config.ad_domain
    @bind_user = config.ad_service_user
    @bind_pass = config.ad_service_pass
  end

  def bind?(uid=nil, password=nil)
    @ldap.auth "#{uid}@#{@ad_domain}", password
    @ldap.bind
  end

  # returns the list of groups to which a user belongs
  # this query is simpler in active directory
  def groups_for_uid(uid)
    service_bind
    filter = Net::LDAP::Filter.eq("samaccountname",uid)
    member = @ldap.search(:filter => filter, :base => @group_base).first
    groups = []
    if member != nil && member.attribute_names.include?(:memberof)
      groups = group_names_from_cn(member)
      groups += group_parents(groups)
    end
    groups
  end

  # active directory can have nested groups. thus, a user's group
  # membership is his "member_of" groups + all of their parents,
  # their parents parents, and so on
  def group_parents(groups=[])
    class_filter = Net::LDAP::Filter.eq("objectclass","group")
    parents = []
    groups.each do |g|
      group_filter = Net::LDAP::Filter.eq("cn", g)
      member = @ldap.search(:filter => class_filter & group_filter, :base => @group_base).first
      if member != nil && member.attribute_names.include?(:memberof)
        parents += group_names_from_cn(member)
        parents += group_parents(parents)
      end
    end
    return parents
  end

  # active directory stores group membership on a users model
  # TODO query by group individually not like this
  def is_in_groups(uid, gids = [], all = false)
    user_groups = groups_for_uid(uid)
    intersection = gids & user_groups
    if all
      return intersection == gids
    else
      return intersection.size > 0
    end
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
  def group_names_from_cn(member)
    p = Proc.new { |g| g.sub(/.*?CN=(.*?),.*/, '\1') }
    member[:memberof].collect(&p)
  end

  # AD generally does not support un-authenticated searching
  # Typically AD admins configure a public user for searching
  def service_bind
    @ldap.auth "#{@bind_user}@#{@ad_domain}", @bind_pass
    raise UnauthenticatedActiveDirectoryException, "Could not bind to AD Service User" unless (@ldap.bind || AppConfig.ldap.ad_anon)
  end

  class UnauthenticatedActiveDirectoryException < StandardError
  end
end
