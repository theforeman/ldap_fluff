require_relative './lib/ldap_test_helper'

class ConfigTest < MiniTest::Test
  include LdapTestHelper

  def test_unsupported_type
    assert_raises(LdapFluff::ConfigError) { LdapFluff.new(config_hash.update :server_type => 'inactive_directory') }
  end

  def test_load_posix
    ldap = LdapFluff.new(config_hash.update :server_type => 'posix')
    assert_instance_of LdapFluff::Posix, ldap.ldap
  end

  def test_load_ad
    ldap = LdapFluff.new(config_hash.update :server_type => 'active_directory')
    assert_instance_of LdapFluff::ActiveDirectory, ldap.ldap
  end

  def test_load_free_ipa
    ldap = LdapFluff.new(config_hash.update :server_type => 'free_ipa')
    assert_instance_of LdapFluff::FreeIPA, ldap.ldap
  end

end
