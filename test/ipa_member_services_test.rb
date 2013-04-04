require_relative './lib/ldap_test_helper'

class TestIPAMemberService < MiniTest::Unit::TestCase
  include LdapTestHelper

  def setup
    config
    @ldap = MiniTest::Mock.new
    @ipams = LdapFluff::FreeIPA::MemberService.new(@ldap,@config.group_base)
  end

  def basic_user
    @ldap.expect(:search, ipa_user_payload, [:filter => ipa_name_filter("john")])
  end

  def test_find_user
    basic_user
    @ipams.ldap = @ldap
    assert_equal ['group', 'bros'], @ipams.find_user_groups("john")
    @ldap.verify
  end

  def test_missing_user
    @ldap.expect(:search, nil, [:filter => ipa_name_filter("john")])
    @ipams.ldap = @ldap
    assert_raises(LdapFluff::FreeIPA::MemberService::UIDNotFoundException) { @ipams.find_user_groups("john").data }
    @ldap.verify
  end

  def test_no_groups
    @ldap.expect(:search, ['',{:memberof=>[]}], [:filter => ipa_name_filter("john")])
    @ipams.ldap = @ldap
    assert_equal [], @ipams.find_user_groups('john')
    @ldap.verify
  end
end
