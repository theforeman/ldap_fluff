require 'minitest/autorun'

class TestAD < MiniTest::Unit::TestCase

  def setup
    @config = MiniTest::Mock.new
    @config.expect(:host, "internet.com")
    @config.expect(:port, "387")
    @config.expect(:encryption, :start_tls)
    @config.expect(:base_dn, "dc=internet,dc=com")
    @config.expect(:group_base, "ou=group,dc=internet,dc=com")
    @config.expect(:ad_service_user, "service")
    @config.expect(:ad_service_pass, "pass")
    @config.expect(:ad_domain, "internet.com")
    @ad = LdapConnection::ActiveDirectory.new(@config)
    @ldap = MiniTest::Mock.new
  end

  def test_good_bind
    @ldap.expect(:auth, nil, ["internet","password"])
    @ldap.expect(:bind, true)
    @ad.ldap = @ldap
    assert_equal @ad.bind?("internet", "password"), true
  end

  def test_bad_bind
    @ldap.expect(:auth, nil, ["internet","password"])
    @ldap.expect(:bind, false)
    @ad.ldap = @ldap
    assert_equal @ad.bind?("internet", "password"), false
  end
end
