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
require 'net/ldap'

class LdapFluff

  attr_reader :ldap

  def initialize(config={})
    config ||= LdapFluff::CONFIG.instance
    type = config.server_type
    if type.respond_to? :to_sym
      if type == :posix
        @ldap = Posix.new(config)
      elsif type == :active_directory
        @ldap = ActiveDirectory.new(config)
      else
        raise Exception, "Unsupported connection type. Supported types = :active_directory, :posix"
      end
    end
  end

  def valid_ldap_authentication?(uid, password)
    @ldap.bind? uid, password
  end

  def ldap_groups(uid)
    @ldap.groups_for_uid(uid)
  end

  def is_in_groups(uid, grouplist)
    @ldap.is_in_groups(uid, grouplist, true)
  end

  # AND or OR all of the filters together
  def self.merge_filters(filters = [], all=false)
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
