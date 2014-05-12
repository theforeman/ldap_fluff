require 'test/lib/ldap_test_helper'

class TestPosix < MiniTest::Test
  include LdapTestHelper

  def setup
    config
    @posix = LdapFluff::Posix.new(@config)
    @ldap  = MiniTest::Mock.new
  end

  def basic_user
    @md = MiniTest::Mock.new
    @md.expect(:find_user_groups, %w(bros), %w(john))
    @posix.member_service = @md
  end

  def test_groups
    basic_user
    assert_equal(@posix.groups_for_uid("john"), %w(bros))
  end

  def test_missing_user
    @md = MiniTest::Mock.new
    @md.expect(:find_user_groups, [], %w(john))
    @posix.member_service = @md
    assert_equal([], @posix.groups_for_uid('john'))
  end

  def test_isnt_in_groups
    basic_user
    @md = MiniTest::Mock.new
    @md.expect(:times_in_groups, 0, ['john', %w(bros), true])
    @posix.member_service = @md
    assert_equal(@posix.is_in_groups('john', %w(bros), true), false)
  end

  def test_is_in_groups
    basic_user
    @md = MiniTest::Mock.new
    @md.expect(:times_in_groups, 1, ['john', %w(bros), true])
    @posix.member_service = @md
    assert_equal(@posix.is_in_groups('john', %w(bros), true), true)
  end

  def test_is_in_no_groups
    basic_user
    assert_equal(@posix.is_in_groups('john', [], true), true)
  end

  def test_good_bind
    @ldap.expect(:bind_as, true, [:filter => "(uid=internet)", :password => "password"])
    @posix.ldap = @ldap
    assert_equal(@posix.bind?("internet", "password"), true)
  end

  def test_bad_bind
    @ldap.expect(:bind_as, false, [:filter => "(uid=internet)", :password => "password"])
    @posix.ldap = @ldap
    assert_equal(@posix.bind?("internet", "password"), false)
  end

  def test_user_exists
    @md = MiniTest::Mock.new
    @md.expect(:find_user, 'notnilluser', %w(john))
    @posix.member_service = @md
    assert(@posix.user_exists?('john'))
  end

  def test_missing_user
    @md = MiniTest::Mock.new
    @md.expect(:find_user, nil, %w(john))
    def @md.find_user(uid)
      raise LdapFluff::Posix::MemberService::UIDNotFoundException
    end
    @posix.member_service = @md
    refute(@posix.user_exists?('john'))
  end

  def test_group_exists
    @md = MiniTest::Mock.new
    @md.expect(:find_group, 'notnillgroup', %w(broskies))
    @posix.member_service = @md
    assert(@posix.group_exists?('broskies'))
  end

  def test_missing_group
    @md = MiniTest::Mock.new
    @md.expect(:find_group, nil, %w(broskies))
    def @md.find_group(uid)
      raise LdapFluff::Posix::MemberService::GIDNotFoundException
    end
    @posix.member_service = @md
    refute(@posix.group_exists?('broskies'))
  end
end
