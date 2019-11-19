# frozen_string_literal: true

require_relative 'ldap_test_helper'

class TestADMemberService < MiniTest::Test
  include LdapTestHelper

  def setup
    super
    # noinspection RubyYardParamTypeMatch
    @adms = LdapFluff::ActiveDirectory::MemberService.new(ldap, config)
  end

  def basic_user
    ldap.expect(:search, ad_user_payload, [filter: ad_name_filter('john')])
    ldap.expect(:search, ad_parent_payload(1), [base: ad_group_dn, scope: 0, attributes: ['memberof']])
    @adms.ldap = ldap
  end

  def basic_group
    ldap.expect(:search, ad_group_payload, [filter: ad_group_filter('broze'), base: config.group_base])
    @adms.ldap = ldap
  end

  def nest_deep(num, ret_method = :ad_parent_payload)
    # add all the expects
    1.upto(num - 1) do |i|
      ldap.expect(:search, send(ret_method, i + 1), [base: ad_group_dn("bros#{i}"), scope: 0, attributes: ['memberof']])
    end

    # terminate or we loop FOREVER
    ldap.expect(:search, [], [base: ad_group_dn("bros#{num}"), scope: 0, attributes: ['memberof']])
  end

  def double_nested(num)
    nest_deep(num, :ad_double_payload)

    (num - 1).downto(1) do |j|
      ldap.expect(:search, [], [base: ad_group_dn("broskies#{j + 1}"), scope: 0, attributes: ['memberof']])
    end
  end

  def test_find_user
    basic_user
    ldap.expect(:search, [], [base: ad_group_dn('bros1'), scope: 0, attributes: ['memberof']])

    assert_equal(%w[group bros1], @adms.find_user_groups('john'))
  end

  def test_nested_groups
    basic_user
    # basic user is memberof 'group'... and 'group' is memberof 'bros1'
    # now make 'bros1' be memberof 'group' again
    ldap.expect(:search, ad_user_payload, [base: ad_group_dn('bros1'), scope: 0, attributes: ['memberof']])

    assert_equal(%w[group bros1], @adms.find_user_groups('john'))
  end

  def test_missing_user
    ldap.expect(:search, nil, [filter: ad_name_filter('john')])
    @adms.ldap = ldap

    assert_raises(LdapFluff::ActiveDirectory::MemberService::UIDNotFoundException) do
      @adms.find_user_groups('john').data
    end
  end

  def test_some_deep_recursion
    basic_user
    nest_deep(25)

    assert_equal(26, @adms.find_user_groups('john').size)
  end

  def test_complex_recursion
    basic_user
    double_nested(5)

    assert_equal(10, @adms.find_user_groups('john').size)
  end

  def test_nil_payload
    assert_equal([], @adms.send(:groups_from_ldap_data, nil))
  end

  def test_empty_user
    ldap.expect(:search, [], [filter: ad_name_filter('john')])
    @adms.ldap = ldap

    assert_raises(LdapFluff::ActiveDirectory::MemberService::UIDNotFoundException) do
      @adms.find_user_groups('john').data
    end
  end

  def test_find_good_user
    ldap.expect(:search, user = ad_user_payload, [filter: ad_name_filter('john')])
    @adms.ldap = ldap

    assert_equal(user.dup, @adms.find_user('john'))
  end

  def test_find_missing_user
    ldap.expect(:search, nil, [filter: ad_name_filter('john')])
    @adms.ldap = ldap

    assert_raises(LdapFluff::ActiveDirectory::MemberService::UIDNotFoundException) do
      @adms.find_user('john')
    end
  end

  def test_find_good_group
    basic_group
    assert_equal(ad_group_payload, @adms.find_group('broze'))
  end

  def test_find_missing_group
    ldap.expect(:search, nil, [filter: ad_group_filter('broze'), base: config.group_base])
    @adms.ldap = ldap

    assert_raises(LdapFluff::ActiveDirectory::MemberService::GIDNotFoundException) do
      @adms.find_group('broze')
    end
  end

  def test_find_by_dn
    ldap.expect(:search, [:result], [filter: ad_group_filter('Foo Bar'), base: 'dc=example,dc=com'])
    @adms.ldap = ldap

    assert_equal([:result], @adms.find_by_dn('cn=Foo Bar,dc=example,dc=com'))
  end

  # In at least one AD installation, users who have commas in their CNs are
  # returned by the server in answer to a group membership query with
  # backslashes before the commas in the CNs. Such escaped commas should not
  # be used when splitting the DN.
  def test_find_by_dn_comma_in_cn
    ldap.expect(:search, [:result], [filter: ad_group_filter('Bar, Foo'), base: 'dc=example,dc=com'])
    @adms.ldap = ldap

    assert_equal([:result], @adms.find_by_dn('cn=Bar\, Foo,dc=example,dc=com'))
  end

  def test_find_by_dn_missing_entry
    ldap.expect(:search, nil, [filter: ad_group_filter('Foo Bar'), base: 'dc=example,dc=com'])
    @adms.ldap = ldap

    assert_raises(LdapFluff::ActiveDirectory::MemberService::UIDNotFoundException) do
      @adms.find_by_dn('cn=Foo Bar,dc=example,dc=com')
    end
  end

  def test_get_login_from_entry
    entry = Net::LDAP::Entry.new('Example User')
    entry[:sAMAccountName] = 'example'

    assert_equal(['example'], @adms.get_login_from_entry(entry))
  end

  def test_get_login_from_entry_missing_attr
    entry = Net::LDAP::Entry.new('Example User')
    assert_nil(@adms.get_login_from_entry(entry))
  end
end
