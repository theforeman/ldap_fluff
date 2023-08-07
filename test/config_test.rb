require 'lib/ldap_test_helper'

class ConfigTest < Minitest::Test
  include LdapTestHelper

  def test_unsupported_type
    assert_raises(LdapFluff::Config::ConfigError) { LdapFluff.new(config_hash.update(:server_type => 'inactive_directory')) }
  end

  def test_load_posix
    ldap = LdapFluff.new(config_hash.update(:server_type => 'posix'))
    assert_instance_of LdapFluff::Posix, ldap.ldap
  end

  def test_load_ad
    ldap = LdapFluff.new(config_hash.update(:server_type => 'active_directory'))
    assert_instance_of LdapFluff::ActiveDirectory, ldap.ldap
  end

  def test_load_free_ipa
    ldap = LdapFluff.new(config_hash.update(:server_type => 'free_ipa'))
    assert_instance_of LdapFluff::FreeIPA, ldap.ldap
  end

  def test_instrumentation_service
    is = Object.new
    net_ldap = LdapFluff.new(config_hash.update(:instrumentation_service => is)).ldap.ldap
    assert_equal is, net_ldap.send(:instrumentation_service)
  end
end
