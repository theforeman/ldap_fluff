# frozen_string_literal: true

require 'ldap_test_helper'

class TestIPA < MiniTest::Test
  include LdapTestHelper

  def setup
    super
    @ipa = LdapFluff::FreeIPA.new(config)
  end

  # default setup for service bind users
  def service_bind(user = 'service', pass = 'pass', ret = true)
    super(ipa_user_bind(user), pass, ret)
  end

  # looks up the uid's full DN via the service account
  def test_good_bind
    user_result.expect(:dn, ipa_user_bind('internet'))
    md.expect(:find_user, user_result, ['internet', true])
    @ipa.member_service = md

    service_bind
    service_bind('internet', 'password')

    assert @ipa.bind?('internet', 'password')
  end

  def test_good_bind_with_dn
    # no expectation on the service account
    service_bind('internet', 'password')

    assert @ipa.bind?(ipa_user_bind('internet'), 'password')
  end

  def test_bad_bind
    service_bind('internet', 'password', false)

    refute @ipa.bind?(ipa_user_bind('internet'), 'password')
  end

  def test_groups
    service_bind
    basic_user

    assert_equal %w[bros], @ipa.groups_for_uid('john')
  end

  def test_bad_user
    service_bind

    md.expect(:find_user_groups, nil) do |uid|
      uid != 'john' || raise(LdapFluff::FreeIPA::MemberService::UIDNotFoundException)
    end
    @ipa.member_service = md

    assert_equal [], @ipa.groups_for_uid('john')
  end

  def test_bad_service_user
    service_bind('service', 'pass', false)

    assert_raises(LdapFluff::FreeIPA::UnauthenticatedException) do
      @ipa.groups_for_uid('john')
    end
  end

  def test_is_in_groups
    service_bind
    basic_user

    assert @ipa.user_in_groups?('john', %w[bros], false)
  end

  def test_is_some_groups
    service_bind
    basic_user

    assert @ipa.user_in_groups?('john', %w[bros buds], false)
  end

  def test_is_in_all_groups
    service_bind
    bigtime_user

    assert @ipa.user_in_groups?('john', %w[broskies bros], true)
  end

  def test_isnt_in_all_groups
    service_bind
    basic_user

    refute @ipa.user_in_groups?('john', %w[bros buds], true)
  end

  def test_isnt_in_groups
    service_bind
    basic_user

    refute @ipa.user_in_groups?('john', %w[broskies], false)
  end

  def test_group_subset
    service_bind
    bigtime_user

    assert @ipa.user_in_groups?('john', %w[broskies], true)
  end

  def test_user_exists
    md.expect(:find_user, 'notnilluser', %w[john])
    @ipa.member_service = md
    service_bind

    assert(@ipa.user_exists?('john'))
  end

  def test_missing_user
    md.expect(:find_user, nil) do |uid|
      uid != 'john' || raise(LdapFluff::FreeIPA::MemberService::UIDNotFoundException)
    end
    @ipa.member_service = md
    service_bind

    refute(@ipa.user_exists?('john'))
  end

  def test_group_exists
    md.expect(:find_group, 'notnillgroup', %w[broskies])
    @ipa.member_service = md
    service_bind

    assert(@ipa.group_exists?('broskies'))
  end

  def test_missing_group
    md.expect(:find_group, nil) do |gid|
      gid != 'broskies' || raise(LdapFluff::FreeIPA::MemberService::GIDNotFoundException)
    end
    @ipa.member_service = md
    service_bind

    refute(@ipa.group_exists?('broskies'))
  end

  def nested_groups
    group = Net::LDAP::Entry.new('gid=foremaners,cn=Groups,cn=accounts,dc=localdomain')
    group[:member] = ['gid=katellers,cn=Groups,cn=accounts,dc=localdomain']

    nested_group = Net::LDAP::Entry.new('gid=katellers,cn=Groups,cn=accounts,dc=localdomain')
    nested_group[:member] = ['uid=testuser,cn=users,cn=accounts,dc=localdomain']

    [group, nested_group]
  end

  def basic_group(ret = nil, name = 'foremaners')
    md.expect(:find_group, [ret], [name])
    md.expect(:find_group, ret, [name, false])
  end

  def test_find_users_in_nested_groups
    group, nested_group = nested_groups

    basic_group(group)
    basic_group(nested_group, 'katellers')
    2.times { service_bind }

    md.expect(:get_logins, ['testuser'], [['uid=testuser,cn=users,cn=accounts,dc=localdomain']])
    @ipa.member_service = md

    assert_equal ['testuser'], @ipa.users_for_gid('foremaners')
  end
end
