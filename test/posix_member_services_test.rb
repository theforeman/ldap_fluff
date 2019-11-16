# frozen_string_literal: true

require 'ldap_test_helper'

class TestPosixMemberService < MiniTest::Test
  include LdapTestHelper

  def setup
    super
    # noinspection RubyYardParamTypeMatch
    @ms = LdapFluff::Posix::MemberService.new(ldap, config)
  end

  def test_find_user
    user = posix_user_payload
    ldap.expect(:search, user, [filter: posix_name_filter('john'), base: config.base_dn])
    @ms.ldap = ldap

    assert_equal user.dup, @ms.find_user('john', config.base_dn)
  end

  def test_find_user_groups
    user = posix_group_payload
    ldap.expect(:search, user, [filter: posix_name_filter('john'), base: config.group_base])
    @ms.ldap = ldap

    assert_equal ['broze'], @ms.find_user_groups('john')
  end

  def test_find_no_groups
    ldap.expect(:search, [], [filter: posix_name_filter('john'), base: config.group_base])
    @ms.ldap = ldap

    assert_equal [], @ms.find_user_groups('john')
  end

  def test_user_exists
    user = posix_user_payload
    ldap.expect(:search, user, [filter: posix_name_filter('john'), base: config.base_dn])
    @ms.ldap = ldap

    assert_equal user.last.dup, @ms.find_user('john', false)
  end

  def test_user_doesnt_exists
    ldap.expect(:search, nil, [filter: posix_name_filter('john'), base: config.base_dn])
    @ms.ldap = ldap

    assert_raises(LdapFluff::Posix::MemberService::UIDNotFoundException) { @ms.find_user('john') }
  end

  def test_group_exists
    group = posix_group_payload
    ldap.expect(:search, group, [filter: group_filter('broze'), base: config.group_base])
    @ms.ldap = ldap

    assert @ms.find_group('broze')
  end

  def test_group_doesnt_exists
    ldap.expect(:search, nil, [filter: group_filter('broze'), base: config.group_base])
    @ms.ldap = ldap

    assert_raises(LdapFluff::Posix::MemberService::GIDNotFoundException) { @ms.find_group('broze') }
  end

  # @deprecated
  def test_times_in_groups
    filter = posix_name_filter('uid') & (group_filter('gid') | group_filter('s'))
    ldap.expect(:search, nil, [base: config.group_base, filter: filter])
    @ms.ldap = ldap

    assert_equal 0, @ms.send(:times_in_groups, 'uid', %w[gid s])
  end
end
