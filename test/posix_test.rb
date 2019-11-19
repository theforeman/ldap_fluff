# frozen_string_literal: true

require_relative 'ldap_test_helper'

class TestPosix < MiniTest::Test
  include LdapTestHelper

  def setup
    super
    @posix = LdapFluff::Posix.new(config)
  end

  def service_bind(user = nil, pass = nil, ret = true)
    super(user || "uid=service,ou=users,#{CONFIG_HASH[:base_dn]}", pass || 'pass', ret)
  end

  def test_groups
    service_bind
    basic_user

    assert_equal %w[bros], @posix.groups_for_uid('john')
  end

  def test_missing_user
    service_bind

    md.expect(:find_user_groups, [], %w[john])
    @posix.member_service = md

    assert_equal([], @posix.groups_for_uid('john'))
  end

  def test_isnt_in_groups
    service_bind
    basic_user

    refute @posix.user_in_groups?('john', %w[broskies], true)
  end

  def test_is_in_groups
    service_bind
    basic_user

    assert @posix.user_in_groups?('john', %w[bros], true)
  end

  def test_is_in_no_groups
    service_bind
    # basic_user

    assert @posix.user_in_groups?('john', [], true)
  end

  # looks up the uid's full DN via the service account
  def test_good_bind
    user_result.expect(:dn, 'uid=internet,dn=example')
    md.expect(:find_user, user_result, ['internet', true])
    @posix.member_service = md

    service_bind
    service_bind('uid=internet,dn=example', 'password')

    assert @posix.bind?('internet', 'password')
  end

  def test_good_bind_with_dn
    # no expectation on the service account
    service_bind('uid=internet,dn=example', 'password')

    assert @posix.bind?('uid=internet,dn=example', 'password')
  end

  def test_bad_bind
    service_bind('uid=internet,dn=example', 'password', false)

    refute @posix.bind?('uid=internet,dn=example', 'password')
  end

  def test_user_exists
    service_bind

    md.expect(:find_user, 'notnilluser', %w[john])
    @posix.member_service = md

    assert(@posix.user_exists?('john'))
  end

  def test_user_doesnt_exists
    service_bind

    md.expect(:find_user, nil) do |uid|
      raise LdapFluff::Posix::MemberService::UIDNotFoundException if uid == 'john'
    end
    @posix.member_service = md

    refute(@posix.user_exists?('john'))
  end

  def test_group_exists
    service_bind

    md.expect(:find_group, 'notnillgroup', %w[broskies])
    @posix.member_service = md

    assert(@posix.group_exists?('broskies'))
  end

  def test_missing_group
    service_bind

    md.expect(:find_group, nil) do |gid|
      raise LdapFluff::Posix::MemberService::GIDNotFoundException if gid == 'broskies'
    end
    @posix.member_service = md

    refute(@posix.group_exists?('broskies'))
  end

  def posix_groups_filter
    group_class_filter('posixGroup') |
      group_class_filter('organizationalunit') |
      group_class_filter('groupOfUniqueNames') |
      group_class_filter('groupOfNames')
  end

  def bind_nested_groups(attr = :memberuid)
    service_bind

    group = Net::LDAP::Entry.new('CN=foremaners,DC=example,DC=com')
    group[attr] = ['katellers']

    nested_group = Net::LDAP::Entry.new('CN=katellers,CN=foremaners,DC=example,DC=com')
    nested_group[attr] = [attr == :member ? 'uid=testuser,' : 'testuser']

    [group, nested_group]
  end

  def test_find_users_in_nested_groups
    group, nested_group = bind_nested_groups
    ldap.expect(:search, [nested_group], [base: group.dn, filter: posix_groups_filter])

    md.expect(:find_group, group, ['foremaners', false])
    @posix.member_service = md

    assert_equal ['testuser'], @posix.users_for_gid('foremaners')
  end

  def test_find_members_in_group
    group, nested_group = bind_nested_groups(:member)
    ldap.expect(:search, [nested_group], [base: group.dn, filter: posix_groups_filter])

    md.expect(:find_group, group, ['foremaners', false])
    md.expect(:get_logins, ['katellers'], [nested_group[:member]])
    @posix.member_service = md

    assert_equal ['katellers'], @posix.users_for_gid('foremaners')
  end

  def test_find_users_in_netgroup
    config.use_netgroups = true

    group, nested_group = bind_nested_groups(:nisnetgrouptriple)
    ldap.expect(:search, [nested_group], [base: group.dn, filter: group_class_filter('nisNetgroup')])

    md.expect(:find_group, group, ['foremaners', false])
    md.expect(:get_netgroup_users, ['katellers'], [['testuser']])
    @posix.member_service = md

    assert_equal ['katellers'], @posix.users_for_gid('foremaners')
  end

  def test_users_in_non_exist_group
    service_bind

    md.expect(:find_group, nil) do |gid, only|
      raise LdapFluff::Posix::MemberService::GIDNotFoundException if gid == 'foremaners' && only == false
    end
    @posix.member_service = md

    assert_equal [], @posix.users_for_gid('foremaners')
  end

  def test_users_for_group
    group, nested_group = bind_nested_groups(:member)

    ldap.expect(:search, [group], [filter: group_filter('foremaners'), base: config.group_base])
    ldap.expect(:search, [nested_group], [base: group.dn, filter: posix_groups_filter])
    @posix.member_service.ldap = ldap

    assert_equal ['testuser'], @posix.users_for_gid('foremaners')
  end
end
