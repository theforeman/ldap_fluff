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
  attr_reader :ad_domain

  def initialize(config={})
    @ldap = Net::LDAP.new :host => AppConfig.ldap.host,
                          :base => AppConfig.ldap.base,
                          :port => AppConfig.ldap.port
    @ad_domain = AppConfig.ldap.ad_domain
  end

  def bind?(uid=nil, password=nil)
    @ldap.auth "#{uid}@#{@ad_domain}", password
    @ldap.bind
  end

  def groups_for_uuid(uid=nil)
    [] 
  end

  def is_in_groups(uid, gids = [], all = false)
    false 
  end
end
