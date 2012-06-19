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

  attr_reader :ad_domain, :group_proc, :group_base

  def initialize(config={})
    @ldap = Net::LDAP.new :host => AppConfig.ldap.host,
                         :base => AppConfig.ldap.base,
                         :port => AppConfig.ldap.port
    # apply custom group base filter
    @group_base = AppConfig.ldap.group_base
    @group_base ||= AppConfig.ldap.base
    @ad_domain = AppConfig.ldap.ad_domain
    @bind_user = AppConfig.ldap.service_user
    @bind_pass = AppConfig.ldap.service_pass
    # return string will be something like 
    # CN=bros,OU=bropeeps,DC=jomara,DC=redhat,DC=com
    # AD group proc from http://erniemiller.org/2008/04/04/simplified-active-directory-authentication/
    @group_proc = Proc.new {|g| g.sub(/.*?CN=(.*?),.*/, '\1')}
  end

  def bind?(uid=nil, password=nil)
    puts "Authing #{uid} @ #{@ad_domain}..."
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
      groups = member[:memberof].collect(&@group_proc)
      groups += group_parents(groups)
    end
    groups
  end

  def group_parents(groups=[])
    class_filter = Net::LDAP::Filter.eq("objectclass","group")
    parents = []
    groups.each do |g|
      group_filter = Net::LDAP::Filter.eq("cn", g)
      member = @ldap.search(:filter => class_filter & group_filter, :base => @group_base).first
      if member != nil && member.attribute_names.include?(:memberof)
        parents += member[:memberof].collect(&@group_proc)
        parents += group_parents(parents)
      end
    end
    return parents
  end

end
