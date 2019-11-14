# frozen_string_literal: true

require 'ldap_test_helper'

class TestPosix < MiniTest::Test
  include LdapTestHelper

  def setup
    super
    @posix = LdapFluff::Posix.new(config)
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

  def test_user_not_exists
    service_bind

    md.expect(:find_user, nil) do |uid|
      uid != 'john' || raise(LdapFluff::Posix::MemberService::UIDNotFoundException)
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
      gid != 'broskies' || raise(LdapFluff::Posix::MemberService::GIDNotFoundException)
    end
    @posix.member_service = md

    refute(@posix.group_exists?('broskies'))
  end

  def nested_groups
    group = Net::LDAP::Entry.new('CN=foremaners,DC=example,DC=com')
    group[:memberuid] = ['katellers']

    nested_group = Net::LDAP::Entry.new('CN=katellers,CN=foremaners,DC=example,DC=com')
    nested_group[:memberuid] = ['testuser']

    [group, nested_group]
  end

  def group_class_filter
    super('posixGroup') |
      super('organizationalunit') |
      super('groupOfUniqueNames') |
      super('groupOfNames')
  end

  def basic_group(ret = nil, name = 'foremaners')
    md.expect(:find_group, [ret], [name])
    md.expect(:find_group, ret, [name, false])
  end

  def test_find_users_in_nested_groups
    service_bind
    group, nested_group = nested_groups

    ldap.expect(:search, [nested_group], [base: group.dn, filter: group_class_filter])
    @posix.ldap = ldap

    basic_group(group)
    @posix.member_service = md

    assert_equal ['testuser'], @posix.users_for_gid('foremaners')
  end
end
