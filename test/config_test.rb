require 'minitest/autorun'
require 'ldap_fluff'

class ConfigTest < MiniTest::Unit::TestCase

  def setup
    @config = MiniTest::Mock.new
    @config.expect(:host, "internet.com")
    @config.expect(:port, "387")
    @config.expect(:encryption, :start_tls)
    @config.expect(:base_dn, "dc=internet,dc=com")
    @config.expect(:group_base, "ou=group,dc=internet,dc=com")
  end

  def test_unsupported_type
    @config.expect(:server_type, :inactive_directory)
    assert_raises(Exception) { LdapFluff.new(@config) }
  end

  def test_load_posix
    @config.expect(:server_type, :posix)
    l = LdapFluff.new(@config)
    assert_instance_of LdapConnection::Posix, l.ldap
  end

  def test_load_ad
    @config.expect(:server_type, :active_directory)
    @config.expect(:ad_service_user, "service")
    @config.expect(:ad_service_pass, "pass")
    @config.expect(:ad_domain, "internet.com")
    l = LdapFluff.new(@config)
    assert_instance_of LdapConnection::ActiveDirectory, l.ldap
  end

end
