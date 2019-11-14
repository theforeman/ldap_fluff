# frozen_string_literal: true

require 'ldap_test_helper'

class TestIPANetgroupMemberService < MiniTest::Test
  include LdapTestHelper

  def setup
    super
    # noinspection RubyYardParamTypeMatch
    @ipams = LdapFluff::FreeIPA::NetgroupMemberService.new(ldap, netgroups_config)
  end

  def basic_user
    ldap.expect(:search, ipa_user_payload, [filter: ipa_name_filter('john')])
  end

  def basic_group
    ldap.expect(:search, ipa_netgroup_payload('broze'), [filter: ipa_group_filter('broze'), base: config.group_base])
  end

  def test_find_user
    basic_user
    @ipams.ldap = ldap

    assert_equal ipa_user_payload, @ipams.find_user('john')
  end

  def test_find_missing_user
    ldap.expect(:search, nil, [filter: ipa_name_filter('john')])
    @ipams.ldap = ldap

    assert_raises(LdapFluff::FreeIPA::MemberService::UIDNotFoundException) { @ipams.find_user('john') }
  end

  def test_find_user_groups
    response = ipa_netgroup_payload('bros', %w[(,john,) (,joe,)])
    ldap.expect(:search, response, [filter: group_class_filter('nisNetgroup'), base: config.group_base])
    @ipams.ldap = ldap

    assert_equal(['bros'], @ipams.find_user_groups('john'))
  end

  def test_find_no_user_groups
    response = ipa_netgroup_payload('bros', ['(,joe,)'])
    ldap.expect(:search, response, [filter: group_class_filter('nisNetgroup'), base: config.group_base])
    @ipams.ldap = ldap

    assert_equal([], @ipams.find_user_groups('john'))
  end

  def test_find_group
    basic_group
    @ipams.ldap = ldap

    assert_equal(ipa_netgroup_payload('broze'), @ipams.find_group('broze'))
  end

  def test_find_missing_group
    ldap.expect(:search, nil, [filter: ipa_group_filter('broze'), base: config.group_base])
    @ipams.ldap = ldap

    assert_raises(LdapFluff::FreeIPA::MemberService::GIDNotFoundException) do
      @ipams.find_group('broze')
    end
  end
end
