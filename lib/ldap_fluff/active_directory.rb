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

class LdapFluff::ActiveDirectory
  attr_accessor :ldap, :member_service

  def initialize(config={})
    @ldap = Net::LDAP.new :host => config.host,
                         :base => config.base_dn,
                         :port => config.port,
                         :encryption => config.encryption
    @group_base = config.group_base
    @group_base ||= config.base_dn
    @ad_domain = config.ad_domain
    @bind_user = config.ad_service_user
    @bind_pass = config.ad_service_pass
    @anon = config.ad_anon_queries

    @member_service = MemberService.new(@ldap,config)
  end

  def bind?(uid=nil, password=nil)
    @ldap.auth "#{uid}@#{@ad_domain}", password
    @ldap.bind
  end

  # AD generally does not support un-authenticated searching
  # Typically AD admins configure a public user for searching
  def service_bind
    unless @anon || bind?(@bind_user, @bind_pass)
      raise UnauthenticatedActiveDirectoryException, "Could not bind to AD Service User"
    end
  end

  # returns the list of groups to which a user belongs
  # this query is simpler in active directory
  def groups_for_uid(uid)
    service_bind
    begin
      member = @member_service.find_user(uid)
    rescue MemberService::UIDNotFoundException
      return []
    end
    member.groups
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

  class UnauthenticatedActiveDirectoryException < StandardError
  end
end
