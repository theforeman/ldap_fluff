require 'lib/ldap_test_helper'

class TestAD < MiniTest::Test
  include LdapTestHelper

  def setup
    super
    @ad   = LdapFluff::ActiveDirectory.new(@config)
  end

  # default setup for service bind users
  def service_bind
    @ldap.expect(:auth, nil, %w(service pass))
    super
  end

  def test_good_bind
    service_bind
    assert_equal(@ad.bind?('service', 'pass'), true)
    @ldap.verify
  end

  def test_bad_bind
    @ldap.expect(:auth, nil, %w(internet password))
    @ldap.expect(:bind, false)
    @ad.ldap = @ldap
    assert_equal(@ad.bind?("internet", "password"), false)
    @ldap.verify
  end

  def test_groups
    service_bind
    basic_user
    assert_equal(@ad.groups_for_uid('john'), %w(bros))
  end

  def test_bad_user
    service_bind
    md = MiniTest::Mock.new
    md.expect(:find_user_groups, nil, %w(john))
    def md.find_user_groups(*args)
      raise LdapFluff::ActiveDirectory::MemberService::UIDNotFoundException
    end
    @ad.member_service = md
    assert_equal(@ad.groups_for_uid('john'), [])
  end

  def test_bad_service_user
    @ldap.expect(:auth, nil, %w(service pass))
    @ldap.expect(:bind, false)
    @ad.ldap = @ldap
    assert_raises(LdapFluff::ActiveDirectory::UnauthenticatedException) do
      @ad.groups_for_uid('john')
    end
  end

  def test_is_in_groups
    service_bind
    basic_user
    assert_equal(@ad.is_in_groups("john", %w(bros), false), true)
  end

  def test_is_some_groups
    service_bind
    basic_user
    assert_equal(@ad.is_in_groups("john", %w(bros buds), false), true)
  end

  def test_isnt_in_all_groups
    service_bind
    basic_user
    assert_equal(@ad.is_in_groups("john", %w(bros buds), true), false)
  end

  def test_isnt_in_groups
    service_bind
    basic_user
    assert_equal(@ad.is_in_groups("john", %w(broskies), false), false)
  end

  def test_group_subset
    service_bind
    bigtime_user
    assert_equal(@ad.is_in_groups("john", %w(broskies), true), true)
  end

  def test_user_exists
    md = MiniTest::Mock.new
    md.expect(:find_user, 'notnilluser', %w(john))
    @ad.member_service = md
    service_bind
    assert(@ad.user_exists?('john'))
  end

  def test_missing_user
    md = MiniTest::Mock.new
    md.expect(:find_user, nil, %w(john))
    def md.find_user(uid)
      raise LdapFluff::ActiveDirectory::MemberService::UIDNotFoundException
    end
    @ad.member_service = md
    service_bind
    refute(@ad.user_exists?('john'))
  end

  def test_group_exists
    md = MiniTest::Mock.new
    md.expect(:find_group, 'notnillgroup', %w(broskies))
    @ad.member_service = md
    service_bind
    assert(@ad.group_exists?('broskies'))
  end

  def test_missing_group
    md = MiniTest::Mock.new
    md.expect(:find_group, nil, %w(broskies))
    def md.find_group(uid)
      raise LdapFluff::ActiveDirectory::MemberService::GIDNotFoundException
    end
    @ad.member_service = md
    service_bind
    refute(@ad.group_exists?('broskies'))
  end

  def test_find_users_in_nested_groups
    group        = Net::LDAP::Entry.new('foremaners')
    nested_group = Net::LDAP::Entry.new('katellers')
    nested_user  = Net::LDAP::Entry.new('testuser')

    group[:member]        = ['CN=katellers,DC=corp,DC=windows,DC=com']
    nested_group[:member] = ['CN=testuser,CN=Users,DC=corp,DC=windows,DC=com']
    nested_group[:objectclass] = ['organizationalunit']
    nested_user[:objectclass]  = ['person']

    md = MiniTest::Mock.new
    2.times { md.expect(:find_group, [group], ['foremaners']) }
    2.times { md.expect(:find_group, [nested_group], ['katellers']) }
    2.times { service_bind }

    md.expect(:find_user,  [nested_group], ['katellers'])
    md.expect(:find_user,  [nested_user],  ['testuser'])
    md.expect(:get_logins, 'testuser', [nested_group.member])
    @ad.member_service = md
    assert_equal @ad.users_for_gid('foremaners'), ['testuser']
  end

end
