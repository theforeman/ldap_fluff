# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ldap_fluff'

require 'minitest/autorun'

module LdapTestHelper
  CONFIG_HASH = {
    host: 'internet.com',
    port: 387,
    encryption: :start_tls,
    base_dn: 'dc=internet,dc=com',
    group_base: 'ou=group,dc=internet,dc=com',
    service_user: 'service',
    service_pass: 'pass',
    server_type: :free_ipa,
    attr_login: nil,
    search_filter: nil
  }.freeze

  MOCK_VARS = %w[ldap md user_result].freeze

  # @!method ldap
  #   @return [MiniTest::Mock, Net::LDAP]
  # @!method md
  #   @return [MiniTest::Mock, LdapFluff::GenericMemberService]
  # @!method user_result
  #   @return [MiniTest::Mock, Net::LDAP::Entry]
  MOCK_VARS.each do |var|
    define_method(var.to_sym) do
      instance_variable_get("@#{var}") || instance_variable_set("@#{var}", (v = MiniTest::Mock.new)) || v
    end
  end

  def setup
    MOCK_VARS.each { |var| instance_variable_set("@#{var}", nil) }
  end

  def teardown
    MOCK_VARS.each { |var| (v = instance_variable_get("@#{var}")) && v.verify }
  end

  # @return [LdapFluff::Config]
  def config(extra = {})
    @config ||= LdapFluff::Config.new CONFIG_HASH.merge(extra)
  end

  # @return [LdapFluff::Config]
  def netgroups_config
    config(use_netgroups: true)
  end

  # default setup for service bind users
  def service_bind(user = 'service', pass = 'pass', ret = true)
    ldap.expect(:auth, nil, [user, pass])
    ldap.expect(:bind, ret)
    test_instance_variable.ldap = ldap
  end

  def basic_user(ret = %w[bros])
    md.expect(:find_user_groups, ret, %w[john])
    test_instance_variable.member_service = md
  end

  def bigtime_user
    basic_user(%w[bros broskies])
  end

  def group_filter(cn)
    Net::LDAP::Filter.eq('cn', cn)
  end

  def group_class_filter(name = 'group')
    Net::LDAP::Filter.eq('objectClass', name)
  end

  def ad_name_filter(name)
    Net::LDAP::Filter.eq('samaccountname', name)
  end

  alias ad_group_filter group_filter

  def ipa_name_filter(name)
    Net::LDAP::Filter.eq('uid', name)
  end

  alias ipa_group_filter group_filter

  def ipa_user_bind(uid)
    "uid=#{uid},cn=users,cn=accounts,#{config.base_dn}"
  end

  def ad_user_dn(name)
    "CN=#{name},CN=Users,#{config.base_dn}"
  end

  def ad_group_dn(name = 'group')
    "cn=#{name},#{config.group_base}"
  end

  def ad_user_payload
    [{ memberof: [ad_group_dn] }]
  end

  def ad_group_payload
    ad_user_payload.tap { |arr| arr[0].merge!(cn: 'group') }
  end

  def ad_parent_payload(num)
    [{ memberof: [ad_group_dn("bros#{num}")] }]
  end

  def ad_double_payload(num)
    [{ memberof: [ad_group_dn("bros#{num}"), ad_group_dn("broskies#{num}")] }]
  end

  def posix_user_payload(name = 'john')
    [{ cn: [name] }]
  end

  def posix_group_payload(name = 'broze')
    posix_user_payload(name)
  end

  def posix_netgroup_payload(cn, netgroups = [])
    [{ cn: [cn], nisnetgrouptriple: netgroups }]
  end

  def ipa_user_payload
    @ipa_user_payload ||= [
      Net::LDAP::Entry.new.tap { |e| e[:cn] = 'John' },
      Net::LDAP::Entry.new.tap { |e| e[:memberof] = %w[cn=group,dc=internet,dc=com cn=bros,dc=internet,dc=com] }
    ]
  end

  def ipa_group_payload
    [{ cn: 'group' }, { memberof: %w[cn=group,dc=internet,dc=com cn=bros,dc=internet,dc=com] }]
  end

  alias ipa_netgroup_payload posix_netgroup_payload

  private

  # @return [LdapFluff::Generic]
  def test_instance_variable
    instance_variable_get("@#{self.class.name.sub(/^Test|Test$/, '').downcase}")
  end
end
