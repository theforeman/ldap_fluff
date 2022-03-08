require 'lib/ldap_test_helper'

class TestNetIQMemberService < MiniTest::Test
  include LdapTestHelper

  def setup
    super
    @ms = LdapFluff::NetIQ::MemberService.new(@ldap, @config)
  end

  def test_find_user
    user = netiq_user_payload
    @ldap.expect(:search, user, [:filter => @ms.name_filter('john'),
                                 :base => config.base_dn])
    @ms.ldap = @ldap
    assert_equal netiq_user_payload, @ms.find_user('john')
    @ldap.verify
  end

  def test_find_user_groups
    user = netiq_group_payload
    @ldap.expect(:search, netiq_user_payload, [:filter => @ms.name_filter('john'), :base => config.base_dn])
    @ldap.expect(:search, user, [:filter => Net::LDAP::Filter.eq('memberuid', 'john') |
                                            Net::LDAP::Filter.eq('member', 'cn=42,ou=usr,o=employee'),
                                 :base => config.group_base, :attributes => ['cn']])
    @ms.ldap = @ldap
    assert_equal ['broze'], @ms.find_user_groups('john')
    @ldap.verify
  end

  def test_find_no_groups
    @ldap.expect(:search, [], [:filter => @ms.name_filter('john'), :base => config.base_dn])
    @ldap.expect(:search, [], [:filter => Net::LDAP::Filter.eq('memberuid', 'john'),
                               :base => config.group_base, :attributes => ['cn']])
    @ms.ldap = @ldap
    assert_equal [], @ms.find_user_groups('john')
    @ldap.verify
  end

  def test_user_exists
    user = netiq_user_payload
    @ldap.expect(:search, user, [:filter => @ms.name_filter('john'),
                                 :base => config.base_dn])
    @ms.ldap = @ldap
    assert @ms.find_user('john')
    @ldap.verify
  end

  def test_user_doesnt_exists
    @ldap.expect(:search, nil, [:filter => @ms.name_filter('john'),
                                :base => config.base_dn])
    @ms.ldap = @ldap
    assert_raises(LdapFluff::NetIQ::MemberService::UIDNotFoundException) { @ms.find_user('john') }
    @ldap.verify
  end

  def test_group_exists
    group = netiq_group_payload
    @ldap.expect(:search, group, [:filter => @ms.group_filter('broze'),
                                  :base => config.group_base])
    @ms.ldap = @ldap
    assert @ms.find_group('broze')
    @ldap.verify
  end

  def test_group_doesnt_exists
    @ldap.expect(:search, nil, [:filter => @ms.group_filter('broze'),
                                :base => config.group_base])
    @ms.ldap = @ldap
    assert_raises(LdapFluff::NetIQ::MemberService::GIDNotFoundException) { @ms.find_group('broze') }
    @ldap.verify
  end

  def test_get_logins
    @ldap.expect(:search, netiq_user_payload,
                 [:filter => @ms.name_filter('42', "workforceid"),
                  :base => 'ou=usr,o=employee'])

    assert_equal ['john'], @ms.get_logins(['cn=42,ou=usr,o=employee'])
  end
end
