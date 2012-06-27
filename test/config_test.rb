require 'minitest/autorun'
require 'ldap_fluff'

class ConfigTest < MiniTest::Unit::TestCase
  include LdapTestHelper

  def setup
    config
  end

  def test_unsupported_type
    @config.server_type = "inactive_directory"
    assert_raises(Exception) { LdapFluff.new(@config) }
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

end
