require 'minitest/autorun'

class TestLDAP < MiniTest::Unit::TestCase
  include LdapTestHelper

  def setup
    config
    @ldap = MiniTest::Mock.new
    @fluff = LdapFluff.new(@config)
  end

  def test_bind
    @ldap.expect(:bind?, true, ['john','password'])
    @fluff.ldap = @ldap
    assert_equal @fluff.authenticate?("john","password"), true
    @ldap.verify
  end

  def test_groups
    @ldap.expect(:groups_for_uid, ['bros'], ['john'])
    @fluff.ldap = @ldap
    assert_equal @fluff.group_list('john'), ['bros']
    @ldap.verify
  end

  def test_group_membership
    @ldap.expect(:is_in_groups, false, ['john',['broskies','girlfriends'],true])
    @fluff.ldap = @ldap
    assert_equal @fluff.is_in_groups?('john',['broskies','girlfriends']), false
    @ldap.verify
  end
end


