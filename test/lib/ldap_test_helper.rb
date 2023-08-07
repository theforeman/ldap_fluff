require 'ldap_fluff'
require 'ostruct'
require 'net/ldap'
require 'minitest/autorun'

module LdapTestHelper
  attr_accessor :group_base, :class_filter, :user

  def config_hash
    { :host => "internet.com",
      :port => "387",
      :encryption => :start_tls,
      :base_dn => "dc=internet,dc=com",
      :group_base => "ou=group,dc=internet,dc=com",
      :service_user => "service",
      :service_pass => "pass",
      :server_type => :free_ipa,
      :attr_login => nil,
      :search_filter => nil }
  end

  def setup
    config
    @ldap = Minitest::Mock.new
  end

  def config
    @config ||= LdapFluff::Config.new config_hash
  end

  def netgroups_config
    @config ||= LdapFluff::Config.new config_hash.merge(:use_netgroups => true)
  end

  def service_bind
    @ldap.expect(:bind, true)
    get_test_instance_variable.ldap = @ldap
  end

  def basic_user
    @md = Minitest::Mock.new
    @md.expect(:find_user_groups, %w[bros], %w[john])
    get_test_instance_variable.member_service = @md
  end

  def bigtime_user
    @md = Minitest::Mock.new
    @md.expect(:find_user_groups, %w[bros broskies], %w[john])
    get_test_instance_variable.member_service = @md
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

  def ad_user_dn(name)
    "CN=#{name},CN=Users,#{@config.base_dn}"
  end

  def ad_group_dn(name = 'group')
    "cn=#{name},#{@config.group_base}"
  end

  def ad_user_payload(name = nil)
    unless name.nil?
      return [{ :memberof => [ad_group_dn], :distinguishedname => [ad_user_dn(name)] }]
    end

    [{ :memberof => [ad_group_dn] }]
  end

  def ad_group_payload
    [{ :cn => "group", :memberof => [ad_group_dn] }]
  end

  def ad_parent_payload(num)
    [{ :memberof => [ad_group_dn("bros#{num}")] }]
  end

  def ad_double_payload(num)
    [{ :memberof => [ad_group_dn("bros#{num}"), ad_group_dn("broskies#{num}")] }]
  end

  def netiq_user_payload
    [{ :uid => ["john"],
       # necessary, because Net::LDAP::Entry would allow both
       'uid' => ["john"],
       :dn => ["cn=42,ou=usr,o=employee"],
       :workeforceid => ["42"] }]
  end

  def netiq_group_payload
    [{ :cn => ["broze"],
       :dn => ["cn=broze,ou=mygroup,ou=apps,o=global"],
       :member => ["cn=42,ou=usr,o=employee"],
       :workforceid => ["21"] }]
  end

  def posix_user_payload
    [{ :cn => ["john"] }]
  end

  def posix_group_payload
    [{ :cn => ["broze"] }]
  end

  def posix_netgroup_payload(cn, netgroups = [])
    [{ :cn => [cn], :nisnetgrouptriple => netgroups }]
  end

  def ipa_user_payload
    @ipa_user_payload_cache ||= begin
      entry_1 = Net::LDAP::Entry.new
      entry_1['cn'] = 'John'
      entry_2 = Net::LDAP::Entry.new
      entry_2['memberof'] = ['cn=group,dc=internet,dc=com', 'cn=bros,dc=internet,dc=com']
      [entry_1, entry_2]
    end
  end

  def ipa_group_payload
    [{ :cn => 'group' }, { :memberof => ['cn=group,dc=internet,dc=com', 'cn=bros,dc=internet,dc=com'] }]
  end

  def ipa_netgroup_payload(cn, netgroups = [])
    [{ :cn => [cn], :nisnetgrouptriple => netgroups }]
  end

  private

  def get_test_instance_variable
    instance_variable_get("@#{self.class.to_s.underscore.split('_')[1..-1].join}")
  end
end
