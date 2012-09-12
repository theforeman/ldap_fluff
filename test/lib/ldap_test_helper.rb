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
        :service_user => "service",
        :service_pass => "pass",
        :ad_domain => "internet.com"
      )
  end

  def ad_name_filter(name)
    Net::LDAP::Filter.eq("samaccountname",name)
  end

  def ipa_name_filter(name)
    Net::LDAP::Filter.eq("uid",name)
  end

  def group_filter(g)
    Net::LDAP::Filter.eq("cn", g)
  end

  def group_class_filter
    Net::LDAP::Filter.eq("objectclass","group")
  end

  def ipa_user_bind(uid)
    "uid=#{uid},cn=users,cn=accounts,#{@config.base_dn}"
  end

  def ad_user_payload
    [{ :memberof => ["CN=group,dc=internet,dc=com"] }]
  end

  def ad_parent_payload(num)
    [{ :memberof => ["CN=bros#{num},dc=internet,dc=com"] }]
  end

  def ad_double_payload(num)
    [{ :memberof => ["CN=bros#{num},dc=internet,dc=com", "CN=broskies#{num},dc=internet,dc=com"] }]
  end

  def posix_user_payload
    [{:cn => ["bros"]}]
  end

  def ipa_user_payload
    [{:cn => 'user'},{:memberof => ['cn=group,dc=internet,dc=com','cn=bros,dc=internet,dc=com']}]
  end
end
