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

class LdapConnection
  attr_reader :ldap, :host, :base, :group_base, :ad_domain

  def initialize(config={})
    type = AppConfig.ldap.server_type
    if type.respond_to? :to_sym
      if type == :posix
        @ldap = LdapConnection::Posix.new(config)
      elsif type == :active_directory
        @ldap = LdapConnection::ActiveDirectory.new(config)
      end
    end
  end

  def bind?(uid=nil, password=nil)
    @ldap.bind? uid, password
  end

  def groups_for_uid(uid=nil)
    @ldap.groups_for_uid uid
  end

  def is_in_groups(uid, gids = [], all = false)
    @ldap.is_in_groups uid, gids, all
  end

  # AND or OR all of the filters together
  def merge_filters(filters = [], all=false)
    if filters.size > 1
      filter = filters[0]
      filters[1..filters.size-1].each do |gfilter|
        if all
          filter = filter & gfilter
        else
          filter = filter | gfilter
        end
      end
    end
  end

end
