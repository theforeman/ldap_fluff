# frozen_string_literal: true

require 'ldap_test_helper'

class TestAD < MiniTest::Test
  include LdapTestHelper

  def setup
    super
    @ad = LdapFluff::ActiveDirectory.new(config)
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
      uid != 'john' || raise(LdapFluff::ActiveDirectory::MemberService::UIDNotFoundException)
    end
    @ad.member_service = md

    assert_equal [], @ad.groups_for_uid('john')
  end

  def test_bad_service_user
    service_bind('service', 'pass', false)

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

  def basic_group(ret = nil, name = 'foremaners')
    md.expect(:find_group, [ret], [name])
    md.expect(:find_group, ret, [name, false])
  end

  def test_subgroups_in_groups_are_ignored
    group = Net::LDAP::Entry.new('foremaners')
    basic_group(group)
    service_bind # 2.times

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
      uid != 'john' || raise(LdapFluff::ActiveDirectory::MemberService::UIDNotFoundException)
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
      gid != 'broskies' || raise(LdapFluff::ActiveDirectory::MemberService::GIDNotFoundException)
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

  def test_find_users_in_nested_groups
    group, nested_group, nested_user = nested_groups
    basic_group(group)
    basic_group(nested_group, 'katellers')
    2.times { service_bind }

    md.expect(:find_by_dn, nested_group, ['CN=katellers,DC=corp,DC=windows,DC=com', true])
    md.expect(:find_by_dn, nested_user, ['CN=Test User,CN=Users,DC=corp,DC=windows,DC=com', true])
    md.expect(:get_login_from_entry, 'testuser', [nested_user])
    @ad.member_service = md

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
    basic_group(group)
    basic_group(nested_group, 'katellers')
    2.times { service_bind }

    md.expect(:find_by_dn, nested_user, ['CN=Test User,CN=Users,DC=corp,DC=windows,DC=com', true])
    md.expect(:find_by_dn, nested_group, ['CN=katellers,DC=corp,DC=windows,DC=com', true])
    md.expect(:get_login_from_entry, 'testuser', [nested_user])
    @ad.member_service = md

    assert_equal ['testuser'], @ad.users_for_gid('foremaners')
  end
end
