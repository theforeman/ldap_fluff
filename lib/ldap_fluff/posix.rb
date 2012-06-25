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

class LdapFluff::Posix

  attr_accessor :ldap, :member_service

  def initialize(config={})
    @ldap = Net::LDAP.new :host => config.host,
                         :base => config.base_dn,
                         :port => config.port,
                         :encryption => config.encryption
    @group_base = config.group_base
    @group_base ||= config.base
    @base = config.base_dn
    @member_service = MemberService.new(@ldap,@group_base)
  end

  def bind?(uid=nil, password=nil)
    @ldap.auth "uid=#{uid},#{@base}", password
    @ldap.bind
  end

  def groups_for_uid(uid)
    member = @member_service.find_user(uid)
    member.groups
  end

  # returns whether a user is a member of ALL or ANY particular groups
  # note: this method is much faster than groups_for_uid
  #
  # gids should be an array of group common names
  #
  # returns true if owner is in ALL of the groups if all=true, otherwise
  # returns true if owner is in ANY of the groups
  def is_in_groups(uid, gids = [], all=true)
    (gids.empty? || @member_service.times_in_groups(uid, gids, all) > 0)
  end

end
