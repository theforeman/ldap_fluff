require 'net/ldap'
require 'ostruct'

module LdapTestHelper
  attr_accessor :group_base, :class_filter, :user

  def config
    @config = OpenStruct.new(
        :host => "internet.com",
        :port => "387",
        :encryption => :start_tls,
        :base_dn => "dc=internet,dc=com",
        :group_base => "ou=group,dc=internet,dc=com",
        :ad_service_user => "service",
        :ad_service_pass => "pass",
        :ad_domain => "internet.com"
      )
  end

  def ad_name_filter(name)
    Net::LDAP::Filter.eq("samaccountname",name)
  end

  def group_filter(g)
    Net::LDAP::Filter.eq("cn", g)
  end

  def group_class_filter
    Net::LDAP::Filter.eq("objectclass","group")
  end

  def ad_user_payload
    [{ :memberof => "CN=group,dc=internet,dc=com" }]
  end

  def posix_user_payload
    [{:cn => ["bros"]}]
  end
end
