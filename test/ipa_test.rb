require 'lib/ldap_test_helper'

class TestIPA < MiniTest::Test
  include LdapTestHelper

  def setup
    super
    @ipa = LdapFluff::FreeIPA.new(@config)
  end

  # default setup for service bind users
  def service_bind
    @ldap.expect(:auth, nil, [ipa_user_bind('service'), "pass"])
    super
  end

  def test_good_bind
    # looks up the uid's full DN via the service account
    @md = MiniTest::Mock.new
    user_result = MiniTest::Mock.new
    user_result.expect(:dn, ipa_user_bind('internet'))
    @md.expect(:find_user, [user_result], %w(internet))
    @ipa.member_service = @md
    service_bind
    @ldap.expect(:auth, nil, [ipa_user_bind('internet'), "password"])
    @ldap.expect(:bind, true)
    assert_equal(@ipa.bind?('internet', 'password'), true)
    @ldap.verify
  end

  def test_good_bind_with_dn
    # no expectation on the service account
    @ldap.expect(:auth, nil, [ipa_user_bind('internet'), "password"])
    @ldap.expect(:bind, true)
    @ipa.ldap = @ldap
    assert_equal(@ipa.bind?(ipa_user_bind('internet'), 'password'), true)
    @ldap.verify
  end

  def test_bad_bind
    @ldap.expect(:auth, nil, [ipa_user_bind('internet'), "password"])
    @ldap.expect(:bind, false)
    @ipa.ldap = @ldap
    assert_equal(@ipa.bind?(ipa_user_bind("internet"), "password"), false)
    @ldap.verify
  end

  def test_groups
    service_bind
    basic_user
    assert_equal(@ipa.groups_for_uid('john'), %w(bros))
  end

  def test_bad_user
    service_bind
    @md = MiniTest::Mock.new
    @md.expect(:find_user_groups, nil, %w(john))
    def @md.find_user_groups(*args)
      raise LdapFluff::FreeIPA::MemberService::UIDNotFoundException
    end
    @ipa.member_service = @md
    assert_equal(@ipa.groups_for_uid('john'), [])
  end

  def test_bad_service_user
    @ldap.expect(:auth, nil, [ipa_user_bind('service'), "pass"])
    @ldap.expect(:bind, false)
    @ipa.ldap = @ldap
    assert_raises(LdapFluff::FreeIPA::UnauthenticatedException) do
      @ipa.groups_for_uid('john')
    end
  end

  def test_is_in_groups
    service_bind
    basic_user
    assert_equal(@ipa.is_in_groups("john", %w(bros), false), true)
  end

  def test_is_some_groups
    service_bind
    basic_user
    assert_equal(@ipa.is_in_groups("john", %w(bros buds), false), true)
  end

  def test_is_in_all_groupss
    service_bind
    bigtime_user
    assert_equal(true, @ipa.is_in_groups("john", %w(broskies bros), true))
  end

  def test_isnt_in_all_groups
    service_bind
    basic_user
    assert_equal(@ipa.is_in_groups("john", %w(bros buds), true), false)
  end

  def test_isnt_in_groups
    service_bind
    basic_user
    assert_equal(@ipa.is_in_groups("john", %w(broskies), false), false)
  end

  def test_group_subset
    service_bind
    bigtime_user
    assert_equal(@ipa.is_in_groups('john', %w(broskies), true), true)
  end

  def test_user_exists
    @md = MiniTest::Mock.new
    @md.expect(:find_user, 'notnilluser', %w(john))
    @ipa.member_service = @md
    service_bind
    assert(@ipa.user_exists?('john'))
  end

  def test_missing_user
    @md = MiniTest::Mock.new
    @md.expect(:find_user, nil, %w(john))
    def @md.find_user(uid)
      raise LdapFluff::FreeIPA::MemberService::UIDNotFoundException
    end
    @ipa.member_service = @md
    service_bind
    refute(@ipa.user_exists?('john'))
  end

  def test_group_exists
    @md = MiniTest::Mock.new
    @md.expect(:find_group, 'notnillgroup', %w(broskies))
    @ipa.member_service = @md
    service_bind
    assert(@ipa.group_exists?('broskies'))
  end

  def test_missing_group
    @md = MiniTest::Mock.new
    @md.expect(:find_group, nil, %w(broskies))
    def @md.find_group(uid)
      raise LdapFluff::FreeIPA::MemberService::GIDNotFoundException
    end
    @ipa.member_service = @md
    service_bind
    refute(@ipa.group_exists?('broskies'))
  end

  def test_find_users_in_nested_groups
    group = Net::LDAP::Entry.new('gid=foremaners,cn=Groups,cn=accounts,dc=localdomain')
    group[:member] = ['gid=katellers,cn=Groups,cn=accounts,dc=localdomain']
    nested_group = Net::LDAP::Entry.new('gid=katellers,cn=Groups,cn=accounts,dc=localdomain')
    nested_group[:member] = ['uid=testuser,cn=users,cn=accounts,dc=localdomain']

    md = MiniTest::Mock.new
    2.times { md.expect(:find_group, [group], ['foremaners']) }
    2.times { md.expect(:find_group, [nested_group], ['katellers']) }
    2.times { service_bind }
    md.expect(:get_logins, ['testuser'], [['uid=testuser,cn=users,cn=accounts,dc=localdomain']])

    @ipa.member_service = md

    assert_equal @ipa.users_for_gid('foremaners'), ['testuser']
    md.verify
  end

end

