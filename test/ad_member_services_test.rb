require 'minitest/autorun'

class TestADMemberService < MiniTest::Unit::TestCase
  include LdapTestHelper

  def setup
    config
    @ldap = MiniTest::Mock.new
    @adms = LdapFluff::ActiveDirectory::MemberService.new(@ldap,@config)
  end

  def test_find_user
    user = ad_user_payload
    @ldap.expect(:search, user, [:filter => ad_name_filter("john")])
    @adms.ldap = @ldap
    assert_equal LdapFluff::ActiveDirectory::Member.new(@ldap, user.first).data, @adms.find_user("john").data
    @ldap.verify
  end

  def test_missing_user
    @ldap.expect(:search, nil, [:filter => ad_name_filter("john")])
    @adms.ldap = @ldap
    assert_raises(LdapFluff::ActiveDirectory::MemberService::UIDNotFoundException) { @adms.find_user("john").data }
    @ldap.verify
  end
end

