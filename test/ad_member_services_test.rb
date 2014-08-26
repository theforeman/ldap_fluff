require 'lib/ldap_test_helper'

class TestADMemberService < MiniTest::Test
  include LdapTestHelper

  def setup
    super
    @adms    = LdapFluff::ActiveDirectory::MemberService.new(@ldap, @config)
    @gfilter = group_filter('group') & group_class_filter
  end

  def basic_user
    @ldap.expect(:search, ad_user_payload, [:filter => ad_name_filter("john")])
    @ldap.expect(:search, ad_parent_payload(1), [:filter => @gfilter, :base => @config.group_base])
  end

  def basic_group
    @ldap.expect(:search, ad_group_payload, [:filter => ad_group_filter("broze"), :base => @config.group_base])
  end

  def nest_deep(n)
    # add all the expects
    1.upto(n - 1) do |i|
      gfilter_bros = group_filter("bros#{i}") & group_class_filter
      @ldap.expect(:search, ad_parent_payload(i + 1), [:filter => gfilter_bros, :base => @config.group_base])
    end
    # terminate or we loop FOREVER
    @ldap.expect(:search, [], [:filter => group_filter("bros#{n}") & group_class_filter, :base => @config.group_base])
  end

  def double_nested(n)
    # add all the expects
    1.upto(n - 1) do |i|
      gfilter_bros = group_filter("bros#{i}") & group_class_filter
      @ldap.expect(:search, ad_double_payload(i + 1), [:filter => gfilter_bros, :base => @config.group_base])
    end
    # terminate or we loop FOREVER
    @ldap.expect(:search, [], [:filter => group_filter("bros#{n}") & group_class_filter, :base => @config.group_base])
    (n - 1).downto(1) do |j|
      gfilter_bros = group_filter("broskies#{j + 1}") & group_class_filter
      @ldap.expect(:search, [], [:filter => gfilter_bros, :base => @config.group_base])
    end
  end

  def test_find_user
    basic_user
    gfilter_bros = group_filter('bros1') & group_class_filter
    @ldap.expect(:search, [], [:filter => gfilter_bros, :base => @config.group_base])
    @adms.ldap = @ldap
    assert_equal(%w(group bros1), @adms.find_user_groups("john"))
    @ldap.verify
  end

  def test_missing_user
    @ldap.expect(:search, nil, [:filter => ad_name_filter("john")])
    @adms.ldap = @ldap
    assert_raises(LdapFluff::ActiveDirectory::MemberService::UIDNotFoundException) do
      @adms.find_user_groups("john").data
    end
    @ldap.verify
  end

  def test_some_deep_recursion
    basic_user
    nest_deep(25)
    @adms.ldap = @ldap
    assert_equal(26, @adms.find_user_groups('john').size)
    @ldap.verify
  end

  def test_complex_recursion
    basic_user
    double_nested(5)
    @adms.ldap = @ldap
    assert_equal(10, @adms.find_user_groups('john').size)
    @ldap.verify
  end

  def test_nil_payload
    assert_equal([], @adms._groups_from_ldap_data(nil))
  end

  def test_empty_user
    @ldap.expect(:search, [], [:filter => ad_name_filter("john")])
    @adms.ldap = @ldap
    assert_raises(LdapFluff::ActiveDirectory::MemberService::UIDNotFoundException) do
      @adms.find_user_groups("john").data
    end
    @ldap.verify
  end

  def test_find_good_user
    basic_user
    @adms.ldap = @ldap
    assert_equal(ad_user_payload, @adms.find_user('john'))
  end

  def test_find_missing_user
    @ldap.expect(:search, nil, [:filter => ad_name_filter("john")])
    @adms.ldap = @ldap
    assert_raises(LdapFluff::ActiveDirectory::MemberService::UIDNotFoundException) do
      @adms.find_user('john')
    end
  end

  def test_find_good_group
    basic_group
    @adms.ldap = @ldap
    assert_equal(ad_group_payload, @adms.find_group('broze'))
  end

  def test_find_missing_group
    @ldap.expect(:search, nil, [:filter => ad_group_filter("broze"), :base => @config.group_base])
    @adms.ldap = @ldap
    assert_raises(LdapFluff::ActiveDirectory::MemberService::GIDNotFoundException) do
      @adms.find_group('broze')
    end
  end

  def test_find_by_dn
    @ldap.expect(:search, [:result], [:filter => Net::LDAP::Filter.eq('cn', 'Foo Bar'), :base => 'dc=example,dc=com'])
    @adms.ldap = @ldap
    assert_equal([:result], @adms.find_by_dn('cn=Foo Bar,dc=example,dc=com'))
    @ldap.verify
  end

  def test_find_by_dn_missing_entry
    @ldap.expect(:search, nil, [:filter => Net::LDAP::Filter.eq('cn', 'Foo Bar'), :base => 'dc=example,dc=com'])
    @adms.ldap = @ldap
    assert_raises(LdapFluff::ActiveDirectory::MemberService::UIDNotFoundException) do
      @adms.find_by_dn('cn=Foo Bar,dc=example,dc=com')
    end
    @ldap.verify
  end

  def test_get_login_from_entry
    entry = Net::LDAP::Entry.new('Example User')
    entry['sAMAccountName'] = 'example'
    assert_equal(['example'], @adms.get_login_from_entry(entry))
  end

  def test_get_login_from_entry_missing_attr
    entry = Net::LDAP::Entry.new('Example User')
    assert_nil(@adms.get_login_from_entry(entry))
  end

end
