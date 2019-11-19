# frozen_string_literal: true

require_relative 'ldap_test_helper'

class TestAD < MiniTest::Test
  include LdapTestHelper

  def setup
    super
    @ad = LdapFluff::ActiveDirectory.new(config)
  end

  def service_bind(user = nil, pass = nil, ret = true)
    super(user || "service@#{CONFIG_HASH[:host]}", pass || 'pass', ret)
  end

  def test_good_bind
    # no expectation on the service account
    service_bind('EXAMPLE\\internet', 'password')

    assert @ad.bind?('EXAMPLE\\internet', 'password')
  end

  def test_good_bind_with_dn
    # no expectation on the service account
    service_bind(user = ad_user_dn('Internet User'), 'password')

    assert @ad.bind?(user.dup, 'password')
  end

  # looks up the account name's full DN via the service account
  def test_good_bind_with_account_name
    user_result.expect(:dn, user = ad_user_dn('Internet User'))
    md.expect(:find_user, user_result, ['internet', true])
    @ad.member_service = md

    service_bind
    service_bind(user.dup, 'password')

    assert @ad.bind?('internet', 'password')
  end

  def test_bad_bind
    service_bind('EXAMPLE\\internet', 'password', false)

    refute @ad.bind?('EXAMPLE\\internet', 'password')
  end

  def test_groups
    service_bind
    basic_user

    assert_equal %w[bros], @ad.groups_for_uid('john')
  end

  def test_bad_user
    service_bind

    md.expect(:find_user_groups, nil) do |uid|
      raise LdapFluff::ActiveDirectory::MemberService::UIDNotFoundException if uid == 'john'
    end
    @ad.member_service = md

    assert_equal [], @ad.groups_for_uid('john')
  end

  def test_bad_service_user
    service_bind(nil, nil, false)

    assert_raises(LdapFluff::ActiveDirectory::UnauthenticatedException) do
      @ad.groups_for_uid('john')
    end
  end

  def test_is_in_groups
    service_bind
    basic_user

    assert @ad.user_in_groups?('john', %w[bros], false)
  end

  def test_is_some_groups
    service_bind
    basic_user

    assert @ad.user_in_groups?('john', %w[bros buds], false)
  end

  def test_isnt_in_all_groups
    service_bind
    basic_user

    refute @ad.user_in_groups?('john', %w[bros buds], true)
  end

  def test_isnt_in_groups
    service_bind
    basic_user

    refute @ad.user_in_groups?('john', %w[broskies], false)
  end

  def test_group_subset
    service_bind
    bigtime_user

    assert @ad.user_in_groups?('john', %w[broskies], true)
  end

  def test_subgroups_in_groups_are_ignored
    service_bind

    group = Net::LDAP::Entry.new('foremaners')
    md.expect(:find_group, group, ['foremaners', false])
    # NOTE: md.expect(:find_by_dn, nil) { raise LdapFluff::ActiveDirectory::MemberService::UIDNotFoundException }
    @ad.member_service = md

    assert_equal [], @ad.users_for_gid('foremaners')
  end

  def test_user_exists
    md.expect(:find_user, 'notnilluser', %w[john])

    @ad.member_service = md
    service_bind

    assert(@ad.user_exists?('john'))
  end

  def test_missing_user
    md.expect(:find_user, nil) do |uid|
      raise LdapFluff::ActiveDirectory::MemberService::UIDNotFoundException if uid == 'john'
    end

    @ad.member_service = md
    service_bind

    refute(@ad.user_exists?('john'))
  end

  def test_group_exists
    md.expect(:find_group, 'notnillgroup', %w[broskies])

    @ad.member_service = md
    service_bind

    assert(@ad.group_exists?('broskies'))
  end

  def test_missing_group
    md.expect(:find_group, nil) do |gid|
      raise LdapFluff::ActiveDirectory::MemberService::GIDNotFoundException if gid == 'broskies'
    end

    @ad.member_service = md
    service_bind

    refute(@ad.group_exists?('broskies'))
  end

  def nested_groups
    group = Net::LDAP::Entry.new('foremaners')
    group[:member] = ['CN=katellers,DC=corp,DC=windows,DC=com']

    nested_group = Net::LDAP::Entry.new('katellers')
    nested_group[:cn] = ['katellers']
    nested_group[:objectclass] = ['organizationalunit']
    nested_group[:member] = ['CN=Test User,CN=Users,DC=corp,DC=windows,DC=com']

    nested_user = Net::LDAP::Entry.new('testuser')
    nested_user[:objectclass] = ['person']

    [group, nested_group, nested_user]
  end

  def bind_nested_groups(group, nested_group)
    md.expect(:find_group, group, ['foremaners', false])
    md.expect(:find_group, nested_group, ['katellers', false])
    @ad.member_service = md

    2.times { service_bind }
  end

  def test_find_users_in_nested_groups
    group, nested_group, nested_user = nested_groups
    bind_nested_groups(group, nested_group)

    md.expect(:find_by_dn, nested_group, [group[:member].first, true])
    md.expect(:find_by_dn, nested_user, [nested_group[:member].first, true])
    md.expect(:get_login_from_entry, 'testuser', [nested_user])

    assert_equal ['testuser'], @ad.users_for_gid('foremaners')
  end

  def empty_nested_groups
    group = Net::LDAP::Entry.new('foremaners')
    group[:member] = ['CN=Test User,CN=Users,DC=corp,DC=windows,DC=com', 'CN=katellers,DC=corp,DC=windows,DC=com']

    nested_group = Net::LDAP::Entry.new('katellers')
    nested_group[:cn] = ['katellers']
    nested_group[:objectclass] = ['organizationalunit']
    nested_group[:memberof] = ['CN=foremaners,DC=corp,DC=windows,DC=com']

    nested_user = Net::LDAP::Entry.new('testuser')
    nested_user[:objectclass] = ['person']

    [group, nested_group, nested_user]
  end

  def test_find_users_with_empty_nested_group
    group, nested_group, nested_user = empty_nested_groups
    bind_nested_groups(group, nested_group)

    md.expect(:find_by_dn, nested_user, [group[:member].first, true])
    md.expect(:find_by_dn, nested_group, [group[:member].last, true])
    md.expect(:get_login_from_entry, 'testuser', [nested_user])

    assert_equal ['testuser'], @ad.users_for_gid('foremaners')
  end

  def test_non_exist_user_in_groups
    service_bind

    md.expect(:find_user_groups, nil) do |uid|
      raise LdapFluff::ActiveDirectory::MemberService::UIDNotFoundException if uid == 'john'
    end
    @ad.member_service = md

    refute @ad.user_in_groups?('john', [nil])
  end

  def test_invalid_users_for_group
    service_bind

    group = Net::LDAP::Entry.new('foremaners').tap { |g| g[:uniquemember] = ['testuser'] }
    md.expect(:find_group, group, ['foremaners', false])

    md.expect(:find_by_dn, nil) do |dn, only|
      raise LdapFluff::ActiveDirectory::MemberService::UIDNotFoundException if dn == 'testuser' && only
    end
    @ad.member_service = md

    assert_equal [], @ad.users_for_gid('foremaners')
  end
end
