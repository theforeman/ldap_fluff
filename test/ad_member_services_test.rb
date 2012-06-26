require 'minitest/autorun'

class TestADMemberService < MiniTest::Unit::TestCase
  include LdapTestHelper

  def setup
    config
    @ldap = MiniTest::Mock.new
    @adms = LdapFluff::ActiveDirectory::MemberService.new(@ldap,@config.group_base)
  end

  def test_find_user
    gfilter = group_filter('group') & group_class_filter
    user = ad_user_payload
    @ldap.expect(:search, user, [:filter => ad_name_filter("john")])
    @ldap.expect(:search, ad_parent_payload(1), [:filter => gfilter, :base => @config.group_base])
    gfilter = group_filter('bros1') & group_class_filter
    @ldap.expect(:search, [], [:filter => gfilter, :base => @config.group_base])
    @adms.ldap = @ldap
    assert_equal ['group', 'bros1'], @adms.find_user_groups("john")
    @ldap.verify
  end

  def test_missing_user
    @ldap.expect(:search, nil, [:filter => ad_name_filter("john")])
    @adms.ldap = @ldap
    assert_raises(LdapFluff::ActiveDirectory::MemberService::UIDNotFoundException) { @adms.find_user_groups("john").data }
    @ldap.verify
  end
end

