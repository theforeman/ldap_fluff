require_relative '../../lib/ldap_fluff'
require 'ostruct'
require 'net/ldap'
require 'minitest/autorun'

module LdapTestHelper
  attr_accessor :group_base, :class_filter, :user

  def config_hash
    { :host         => "internet.com",
      :port         => "387",
      :encryption   => :start_tls,
      :base_dn      => "dc=internet,dc=com",
      :group_base   => "ou=group,dc=internet,dc=com",
      :service_user => "service",
      :service_pass => "pass",
      :ad_domain    => "internet.com",
      :server_type  => :free_ipa
    }
  end

  def config
    @config ||= LdapFluff::Config.new config_hash
  end

  def ad_name_filter(name)
    Net::LDAP::Filter.eq("samaccountname", name)
  end

  def ad_group_filter(name)
    Net::LDAP::Filter.eq("cn", name)
  end

  def ipa_name_filter(name)
    Net::LDAP::Filter.eq("uid", name)
  end

  def ipa_group_filter(name)
    Net::LDAP::Filter.eq("cn", name)
  end

  def group_filter(g)
    Net::LDAP::Filter.eq("cn", g)
  end

  def group_class_filter
    Net::LDAP::Filter.eq("objectclass", "group")
  end

  def ipa_user_bind(uid)
    "uid=#{uid},cn=users,cn=accounts,#{@config.base_dn}"
  end

  def ad_user_payload
    [{ :memberof => ["CN=group,dc=internet,dc=com"] }]
  end

  def ad_group_payload
    [{ :cn => "broze", :memberof => ["CN=group,dc=internet,dc=com"] }]
  end

  def ad_parent_payload(num)
    [{ :memberof => ["CN=bros#{num},dc=internet,dc=com"] }]
  end

  def ad_double_payload(num)
    [{ :memberof => ["CN=bros#{num},dc=internet,dc=com", "CN=broskies#{num},dc=internet,dc=com"] }]
  end

  def posix_user_payload
    [{ :cn => ["bros"] }]
  end

  def posix_group_payload
    [{ :cn => ["broze"] }]
  end

  def ipa_user_payload
    [{ :cn => 'john' }, { :memberof => ['cn=group,dc=internet,dc=com', 'cn=bros,dc=internet,dc=com'] }]
  end

  def ipa_group_payload
    [{ :cn => 'group' }, { :memberof => ['cn=group,dc=internet,dc=com', 'cn=bros,dc=internet,dc=com'] }]
  end
end
