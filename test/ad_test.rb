require 'minitest/autorun'

class TestAD < MiniTest::Unit::TestCase
  include LdapTestHelper

  def setup
    config
    @ad = LdapConnection::ActiveDirectory.new(@config)
    @ldap = MiniTest::Mock.new
  end

  def test_good_bind
    @ldap.expect(:auth, nil, ["internet@internet.com","password"])
    @ldap.expect(:bind, true)
    @ad.ldap = @ldap
    assert_equal @ad.bind?("internet", "password"), true
    @ldap.verify
  end

  def test_bad_bind
    @ldap.expect(:auth, nil, ["internet@internet.com","password"])
    @ldap.expect(:bind, false)
    @ad.ldap = @ldap
    assert_equal @ad.bind?("internet", "password"), false
    @ldap.verify
  end

  def test_no_groups
    @ldap.expect(:auth, nil, ["service@internet.com","pass"])
    @ldap.expect(:bind, true)
    m = MiniTest::Mock.new
    m.expect(:groups, [])
    LdapConnection::ActiveDirectory::Member.stub :new, m do
      #assert_equal @ad.groups_for_uid('john'), []
    end
  end

  def test_groups
    @ldap.expect(:search, @user, [:filter=>ad_name_filter("john"),:base=>@group_base])
    # mocks for parent query
    @ldap.expect(:search, [],[:filter => (group_filter("group") & @class_filter), :base=>@group_base])
    @ad.ldap = @ldap
    #assert_equal @ad.groups_for_uid('john'), ['group']
  end

end
