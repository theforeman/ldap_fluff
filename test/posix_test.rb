require 'minitest/autorun'

class TestPosix < MiniTest::Unit::TestCase
  include LdapTestHelper

  def setup
    config
    @posix = LdapFluff::Posix.new(@config)
    @ldap = MiniTest::Mock.new
  end

  def basic_user
    m = OpenStruct.new(:groups => ['bros'])
    @md = MiniTest::Mock.new
    @md.expect(:find_user, m, ["john"])
    @posix.member_service = @md
  end

  def test_groups
    basic_user
    assert_equal @posix.groups_for_uid("john"), ['bros']
  end

  def test_missing_user
    @md = MiniTest::Mock.new
    user = LdapFluff::Posix::Member.new
    @md.expect(:find_user, user, ['john'])
    @posix.member_service = @md
    assert_equal [], @posix.groups_for_uid('john')
  end

  def test_isnt_in_groups
    basic_user
    @md = MiniTest::Mock.new
    @md.expect(:times_in_groups, 0, ['john', ['bros'], true])
    @posix.member_service = @md
    assert_equal @posix.is_in_groups('john', ['bros'], true), false
  end

  def test_is_in_groups
    basic_user
    @md = MiniTest::Mock.new
    @md.expect(:times_in_groups, 1, ['john', ['bros'], true])
    @posix.member_service = @md
    assert_equal @posix.is_in_groups('john', ['bros'], true), true
  end

  def test_is_in_no_groups
    basic_user
    assert_equal @posix.is_in_groups('john', [], true), true
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
