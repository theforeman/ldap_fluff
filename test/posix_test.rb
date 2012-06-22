require 'minitest/autorun'

class TestMeme < MiniTest::Unit::TestCase

  @default_user = { :memberof => "group1" }
  @group = { :memberof => "jeans" }
  @jeans = { }

  def setup
    @config = MiniTest::Mock.new
    @config.expect(:host, "internet.com")
    @config.expect(:port, "387")
    @config.expect(:encryption, :start_tls)
    @config.expect(:base_dn, "dc=internet,dc=com")
    @config.expect(:group_base, "ou=group,dc=internet,dc=com")
    @posix = LdapConnection::Posix.new(@config)
    @ldap = MiniTest::Mock.new
  end

  def test_good_bind
    @ldap.expect(:auth, nil, ["internet","password"])
    @ldap.expect(:bind, true)
    @posix.ldap = @ldap
    assert_equal @posix.bind?("internet", "password"), true
  end

  def test_bad_bind
    @ldap.expect(:auth, nil, ["internet","password"])
    @ldap.expect(:bind, false)
    @posix.ldap = @ldap
    assert_equal @posix.bind?("internet", "password"), false
  end

end
