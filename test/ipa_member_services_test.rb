require 'lib/ldap_test_helper'

class TestIPAMemberService < MiniTest::Test
  include LdapTestHelper

  def setup
    config
    @ldap  = MiniTest::Mock.new
    @ipams = LdapFluff::FreeIPA::MemberService.new(@ldap, @config.group_base)
  end

  def basic_user
    @ldap.expect(:search, ipa_user_payload, [:filter => ipa_name_filter("john")])
  end

  def basic_group
    @ldap.expect(:search, ipa_group_payload, [:filter => ipa_group_filter("broze"), :base => @config.group_base])
  end

  def test_find_user
    basic_user
    @ipams.ldap = @ldap
    assert_equal(%w(group bros), @ipams.find_user_groups("john"))
    @ldap.verify
  end

  def test_missing_user
    @ldap.expect(:search, nil, [:filter => ipa_name_filter("john")])
    @ipams.ldap = @ldap
    assert_raises(LdapFluff::FreeIPA::MemberService::UIDNotFoundException) do
      @ipams.find_user_groups("john").data
    end
    @ldap.verify
  end

  def test_no_groups
    @ldap.expect(:search, ['', { :memberof => [] }], [:filter => ipa_name_filter("john")])
    @ipams.ldap = @ldap
    assert_equal([], @ipams.find_user_groups('john'))
    @ldap.verify
  end

  def test_find_good_user
    basic_user
    @ipams.ldap = @ldap
    assert_equal(ipa_user_payload, @ipams.find_user('john'))
  end

  def test_find_missing_user
    @ldap.expect(:search, nil, [:filter => ipa_name_filter("john")])
    @ipams.ldap = @ldap
    assert_raises(LdapFluff::FreeIPA::MemberService::UIDNotFoundException) do
      @ipams.find_user('john')
    end
  end

  def test_find_good_group
    basic_group
    @ipams.ldap = @ldap
    assert_equal(ipa_group_payload, @ipams.find_group('broze'))
  end

  def test_find_missing_group
    @ldap.expect(:search, nil, [:filter => ipa_group_filter("broze"), :base => @config.group_base])
    @ipams.ldap = @ldap
    assert_raises(LdapFluff::FreeIPA::MemberService::GIDNotFoundException) do
      @ipams.find_group('broze')
    end
  end

end
