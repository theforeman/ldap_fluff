require 'lib/ldap_test_helper'

class TestPosixMemberService < Minitest::Test
  include LdapTestHelper

  def setup
    super
    @ms = LdapFluff::Posix::MemberService.new(@ldap, @config)
  end

  def test_find_user
    user = posix_user_payload
    @ldap.expect(:search, user, [:filter => @ms.name_filter('john'),
                                 :base => config.base_dn])
    @ms.ldap = @ldap
    assert_equal posix_user_payload, @ms.find_user('john')
    @ldap.verify
  end

  def test_find_user_groups
    group = posix_group_payload
    user = posix_user_payload
    username = 'john'

    @ldap.expect(:search, user, [:filter => @ms.name_filter(username),
                                 :base => config.base_dn])
    filter = Net::LDAP::Filter.eq('memberuid', username)
    @ldap.expect(:search, group, [:filter => filter,
                                 :base => config.group_base,
                                 :attributes => ["cn"]])
    @ms.ldap = @ldap
    assert_equal ['broze'], @ms.find_user_groups(username)
    @ldap.verify
  end

  def test_find_user_groups_rfc4519
    @ms.instance_variable_set('@use_rfc4519_group_membership', true)

    group = posix_group_payload
    user = posix_user_payload
    username = 'john'

    @ldap.expect(:search, user, [:filter => @ms.name_filter(username),
                                 :base => config.base_dn])
    filter = [Net::LDAP::Filter.eq('memberuid', username),
              Net::LDAP::Filter.eq('member', user.first[:dn].first) & Net::LDAP::Filter.eq('objectClass', 'groupOfNames'),
              Net::LDAP::Filter.eq('uniquemember', user.first[:dn].first) & Net::LDAP::Filter.eq('objectClass', 'groupOfUniqueNames')
             ].reduce(&:|)

    @ldap.expect(:search, group, [:filter => filter,
                                 :base => config.group_base,
                                 :attributes => ["cn"]])
    @ms.ldap = @ldap
    assert_equal ['broze'], @ms.find_user_groups(username)
    @ldap.verify
  end

  def test_find_no_groups
    user = posix_user_payload
    username = 'john'
    @ldap.expect(:search, user, [:filter => @ms.name_filter(username),
                                 :base => config.base_dn])
    filter = @ms.send(:user_group_filter, username, user.first[:dn].first)
    @ldap.expect(:search, [], [:filter => filter,
                               :base => config.group_base,
                               :attributes => ["cn"]])
    @ms.ldap = @ldap
    assert_equal [], @ms.find_user_groups(username)
    @ldap.verify
  end

  def test_user_exists
    user = posix_user_payload
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
    assert_raises(LdapFluff::Posix::MemberService::UIDNotFoundException) { @ms.find_user('john') }
    @ldap.verify
  end

  def test_group_exists
    group = posix_group_payload
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
    assert_raises(LdapFluff::Posix::MemberService::GIDNotFoundException) { @ms.find_group('broze') }
    @ldap.verify
  end
end
