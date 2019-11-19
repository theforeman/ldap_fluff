# frozen_string_literal: true

require_relative 'ldap_test_helper'

class TestIPA < MiniTest::Test
  include LdapTestHelper

  def setup
    super
    @ipa = LdapFluff::FreeIPA.new(config)
  end

  def service_bind(user = nil, pass = nil, ret = true)
    super(user || ipa_user_bind('service'), pass || 'pass', ret)
  end

  # looks up the uid's full DN via the service account
  def test_good_bind
    user_result.expect(:dn, uid = ipa_user_bind('internet'))
    md.expect(:find_user, user_result, ['internet', true])
    @ipa.member_service = md

    service_bind
    service_bind(uid.dup, 'password')

    assert @ipa.bind?('internet', 'password')
  end

  def test_good_bind_with_dn
    # no expectation on the service account
    service_bind(uid = ipa_user_bind('internet'), 'password')

    assert @ipa.bind?(uid.dup, 'password')
  end

  def test_bad_bind
    service_bind(uid = ipa_user_bind('internet'), 'password', false)

    refute @ipa.bind?(uid.dup, 'password')
  end

  def test_groups
    service_bind
    basic_user

    assert_equal %w[bros], @ipa.groups_for_uid('john')
  end

  def test_bad_user
    service_bind

    md.expect(:find_user_groups, nil) do |uid|
      raise LdapFluff::FreeIPA::MemberService::UIDNotFoundException if uid == 'john'
    end
    @ipa.member_service = md

    assert_equal [], @ipa.groups_for_uid('john')
  end

  def test_bad_service_user
    service_bind(nil, nil, false)

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
      raise LdapFluff::FreeIPA::MemberService::UIDNotFoundException if uid == 'john'
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
      raise LdapFluff::FreeIPA::MemberService::GIDNotFoundException if gid == 'broskies'
    end
    @ipa.member_service = md
    service_bind

    refute(@ipa.group_exists?('broskies'))
  end

  def nested_groups
    group = Net::LDAP::Entry.new('gid=foremaners,cn=Groups,cn=accounts,dc=localdomain')
    group[:member] = ['gid=katellers,cn=Groups,cn=accounts,dc=localdomain']

    nested_group = Net::LDAP::Entry.new(group[:member].first)
    nested_group[:member] = ['uid=testuser,cn=users,cn=accounts,dc=localdomain']

    [group, nested_group]
  end

  def test_find_users_in_nested_groups
    group, nested_group = nested_groups

    md.expect(:find_group, group, ['foremaners', false])
    md.expect(:find_group, nested_group, ['katellers', false])
    2.times { service_bind }

    md.expect(:get_logins, ['testuser'], [nested_group[:member]])
    @ipa.member_service = md

    assert_equal ['testuser'], @ipa.users_for_gid('foremaners')
  end

  def test_insufficient_privileges_user
    @ipa.member_service.ldap = service_bind
    ldap.expect(:search, [nil], [filter: ipa_name_filter('john')])

    assert_raises(LdapFluff::FreeIPA::UnauthenticatedException) { @ipa.groups_for_uid('john') }
  end

  def test_find_users_for_netgroup
    config.use_netgroups = true
    @ipa.member_service.ldap = service_bind

    group = Net::LDAP::Entry.new('gid=foremaners').tap { |g| g[:nisnetgrouptriple] = %w[(,john,) (,joe,)] }
    ldap.expect(:search, [group], [filter: ipa_group_filter('foremaners'), base: config.group_base])

    assert_equal %w[john joe], @ipa.users_for_gid('foremaners')
  end
end
