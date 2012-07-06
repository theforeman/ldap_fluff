require 'minitest/autorun'

class TestAD < MiniTest::Unit::TestCase
  include LdapTestHelper

  def setup
    config
    @ad = LdapFluff::ActiveDirectory.new(@config)
    @ldap = MiniTest::Mock.new
  end

  # default setup for service bind users
  def service_bind
    @ldap.expect(:auth, nil, ["service@internet.com","pass"])
    @ldap.expect(:bind, true)
    @ad.ldap = @ldap
  end

  def basic_user
    @md = MiniTest::Mock.new
    @md.expect(:find_user_groups, ['bros'], ["john"])
    @ad.member_service = @md
  end

  def bigtime_user
    @md = MiniTest::Mock.new
    @md.expect(:find_user_groups, ['bros','broskies'], ["john"])
    @ad.member_service = @md
  end

  def test_good_bind
    @ldap.expect(:auth, nil, ["internet@internet.com","password"])
    @ldap.expect(:bind, true)
    @ad.ldap = @ldap
    assert_equal @ad.bind?("internet", "password"), true
    @ldap.verify
  end

  def test_bad_bind
    @ldap.expect(:auth, nil, ["internet@internet.com","password"])
    @ldap.expect(:bind, false)
    @ad.ldap = @ldap
    assert_equal @ad.bind?("internet", "password"), false
    @ldap.verify
  end

  def test_groups
    service_bind
    basic_user
    assert_equal @ad.groups_for_uid('john'), ['bros']
  end

  def test_bad_user
    service_bind
    @md = MiniTest::Mock.new
    @md.expect(:find_user_groups, nil, ["john"])
    def @md.find_user_groups(*args)
      raise LdapFluff::ActiveDirectory::MemberService::UIDNotFoundException
    end
    @ad.member_service = @md
    assert_equal @ad.groups_for_uid('john'), []
  end

  def test_bad_service_user
    @ldap.expect(:auth, nil, ["service@internet.com","pass"])
    @ldap.expect(:bind, false)
    @ad.ldap = @ldap
    assert_raises(LdapFluff::ActiveDirectory::UnauthenticatedActiveDirectoryException) { @ad.groups_for_uid('john') }
  end

  def test_is_in_groups
    service_bind
    basic_user
    assert_equal @ad.is_in_groups("john",["bros"],false), true
  end

  def test_is_some_groups
    service_bind
    basic_user
    assert_equal @ad.is_in_groups("john",["bros","buds"],false), true
  end

  def test_isnt_in_all_groups
    service_bind
    basic_user
    assert_equal @ad.is_in_groups("john",["bros","buds"],true), false
  end

  def test_isnt_in_groups
    service_bind
    basic_user
    assert_equal @ad.is_in_groups("john", ["broskies"],false), false
  end

  def test_group_subset
    service_bind
    bigtime_user
    assert_equal @ad.is_in_groups("john", ["broskies"],true), true
  end
end
