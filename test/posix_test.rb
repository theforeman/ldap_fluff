require 'minitest/autorun'

class TestPosix < MiniTest::Unit::TestCase
  include LdapTestHelper

  def setup
    config
    @posix = LdapConnection::Posix.new(@config)
    @ldap = MiniTest::Mock.new
  end

  def test_good_bind
    @ldap.expect(:auth, nil, ["uid=internet,dc=internet,dc=com","password"])
    @ldap.expect(:bind, true)
    @posix.ldap = @ldap
    assert_equal @posix.bind?("internet", "password"), true
  end

  def test_bad_bind
    @ldap.expect(:auth, nil, ["uid=internet,dc=internet,dc=com","password"])
    @ldap.expect(:bind, false)
    @posix.ldap = @ldap
    assert_equal @posix.bind?("internet", "password"), false
  end
end
