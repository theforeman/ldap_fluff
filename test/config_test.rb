# frozen_string_literal: true

require 'ldap_test_helper'

class ConfigTest < MiniTest::Test
  include LdapTestHelper

  def test_unsupported_type
    assert_raises(LdapFluff::Config::ConfigError) { LdapFluff.new CONFIG_HASH.merge(server_type: 'inactive_directory') }
  end

  def test_load_posix
    fluff = LdapFluff.new CONFIG_HASH.merge(server_type: 'posix')
    assert_instance_of LdapFluff::Posix, fluff.ldap
  end

  def test_load_ad
    fluff = LdapFluff.new CONFIG_HASH.merge(server_type: :active_directory)
    assert_instance_of LdapFluff::ActiveDirectory, fluff.ldap
  end

  def test_load_free_ipa
    fluff = LdapFluff.new CONFIG_HASH.merge(server_type: 'free_ipa')
    assert_instance_of LdapFluff::FreeIPA, fluff.ldap
  end

  def test_instrumentation_service
    is = Object.new
    net_ldap = LdapFluff.new(CONFIG_HASH.merge(instrumentation_service: is)).ldap.ldap
    assert_equal is, net_ldap.send(:instrumentation_service)
  end

  def test_missing_keys
    assert_raises(LdapFluff::Config::ConfigError) { LdapFluff.new }
  end

  def test_unknown_keys
    assert_raises(LdapFluff::Config::ConfigError) { LdapFluff.new CONFIG_HASH.merge(unknown_key: nil) }
  end

  def test_anon_queries
    fluff = LdapFluff.new CONFIG_HASH.merge('anon_queries' => true, service_user: nil)
    assert fluff.ldap.user_in_groups?(nil)
  end

  def test_nil_required_keys
    %w[host port base_dn server_type service_user service_pass].each do |key|
      assert_raises(LdapFluff::Config::ConfigError) { LdapFluff.new CONFIG_HASH.merge(key => nil) }
    end
  end

  def test_invalid_anon_queries_set
    assert_raises(LdapFluff::Config::ConfigError) { LdapFluff.new CONFIG_HASH.merge(anon_queries: 0) }
  end

  def test_nil_group_base
    fluff = LdapFluff.new CONFIG_HASH.merge('group_base' => nil)
    assert_equal fluff.ldap.config.base_dn, fluff.ldap.config.group_base
  end

  def test_load_posix_netgroup
    fluff = LdapFluff.new CONFIG_HASH.merge('server_type' => :posix, use_netgroups: 1)
    assert_instance_of LdapFluff::Posix::NetgroupMemberService, fluff.ldap.member_service
  end

  def test_bad_search_filter
    assert_output(nil, /\bSearch filter unavailable\b/) do
      fluff = LdapFluff.new CONFIG_HASH.merge('search_filter' => 'bad-filter')
      assert_nil fluff.ldap.member_service.search_filter
    end
  end
end
