require 'minitest/autorun'

class TestPosixMemberService < MiniTest::Unit::TestCase
  include LdapTestHelper

  def setup
    config
    @ldap = MiniTest::Mock.new
    @ms = LdapFluff::Posix::MemberService.new(@ldap, @config.group_base)
  end

  def test_find_user
    user = posix_user_payload
    expected_filter = @ms.name_filter('john')
    puts "Expecting #{expected_filter} : #{@group_base}"
    @ldap.expect(:search,
                 user,
                 [
                   :filter => @ms.name_filter('john'),
                  :base =>@group_base
                 ]
                )
    @ms.ldap = @ldap
    m = LdapFluff::Posix::Member.new(['bros'])
    assert_equal m, @ms.find_user('john')
    @ldap.verify
  end
end
