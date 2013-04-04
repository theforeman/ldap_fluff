require_relative './lib/ldap_test_helper'

class ConfigTest < MiniTest::Unit::TestCase
  include LdapTestHelper

  def setup
    config
  end

  def test_unsupported_type
    @config.server_type = "inactive_directory"
    assert_raises(LdapFluff::ConfigError) { LdapFluff.new(@config) }
  end

  def test_load_posix
    @config.server_type = "posix"
    l = LdapFluff.new(@config)
    assert_instance_of LdapFluff::Posix, l.ldap
  end

  def test_load_ad
    @config.server_type = "active_directory"
    l = LdapFluff.new(@config)
    assert_instance_of LdapFluff::ActiveDirectory, l.ldap
  end

  def test_load_ad
    @config.server_type = "free_ipa"
    l = LdapFluff.new(@config)
    assert_instance_of LdapFluff::FreeIPA, l.ldap
  end

end
