# frozen_string_literal: true

require 'ldap_test_helper'

class ConfigTest < MiniTest::Test
  include LdapTestHelper

  def test_unsupported_type
    assert_raises(LdapFluff::Config::ConfigError) do
      LdapFluff.new CONFIG_HASH.merge(server_type: 'inactive_directory')
    end
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
end
