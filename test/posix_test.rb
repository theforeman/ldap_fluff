require_relative './lib/ldap_test_helper'

class TestPosix < MiniTest::Test
  include LdapTestHelper

  def setup
    config
    @posix = LdapFluff::Posix.new(@config)
    @ldap  = MiniTest::Mock.new
  end

  def basic_user
    @md = MiniTest::Mock.new
    @md.expect(:find_user_groups, ['bros'], ["john"])
    @posix.member_service = @md
  end

  def test_groups
    basic_user
    assert_equal @posix.groups_for_uid("john"), ['bros']
  end

  def test_missing_user
    @md = MiniTest::Mock.new
    @md.expect(:find_user_groups, [], ['john'])
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
    @ldap.expect(:auth, nil, ["uid=internet,dc=internet,dc=com", "password"])
    @ldap.expect(:bind, true)
    @posix.ldap = @ldap
    assert_equal @posix.bind?("internet", "password"), true
  end

  def test_bad_bind
    @ldap.expect(:auth, nil, ["uid=internet,dc=internet,dc=com", "password"])
    @ldap.expect(:bind, false)
    @posix.ldap = @ldap
    assert_equal @posix.bind?("internet", "password"), false
  end

  def test_user_exists
    @md = MiniTest::Mock.new
    @md.expect(:find_user, 'notnilluser', ["john"])
    @posix.member_service = @md
    assert @posix.user_exists?('john')
  end

  def test_missing_user
    @md = MiniTest::Mock.new
    @md.expect(:find_user, nil, ['john'])
    def @md.find_user uid
      raise LdapFluff::Posix::MemberService::UIDNotFoundException
    end
    @posix.member_service = @md
    assert !@posix.user_exists?('john')
  end

  def test_group_exists
    @md = MiniTest::Mock.new
    @md.expect(:find_group, 'notnillgroup', ["broskies"])
    @posix.member_service = @md
    assert @posix.group_exists?('broskies')
  end

  def test_missing_group
    @md = MiniTest::Mock.new
    @md.expect(:find_group, nil, ['broskies'])
    def @md.find_group uid
      raise LdapFluff::Posix::MemberService::GIDNotFoundException
    end
    @posix.member_service = @md
    assert !@posix.group_exists?('broskies')
  end
end
