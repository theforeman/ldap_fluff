# frozen_string_literal: true

require 'ldap_test_helper'

class TestLDAP < MiniTest::Test
  include LdapTestHelper

  def setup
    super
    @fluff = LdapFluff.new(CONFIG_HASH)
  end

  def test_bind
    ldap.expect(:bind?, true, %w[john password])
    @fluff.ldap = ldap

    assert @fluff.authenticate?('john', 'password')
  end

  def test_groups
    ldap.expect(:groups_for_uid, %w[bros], %w[john])
    @fluff.ldap = ldap

    assert_equal %w[bros], @fluff.group_list('john')
  end

  def test_group_membership
    ldap.expect(:user_in_groups?, false, ['john', %w[broskies girlfriends], true])
    @fluff.ldap = ldap

    refute @fluff.user_in_groups?('john', %w[broskies girlfriends])
  end

  def test_valid_user
    ldap.expect(:user_exists?, true, %w[john])
    @fluff.ldap = ldap

    assert(@fluff.valid_user?('john'))
  end

  def test_valid_group
    ldap.expect(:group_exists?, true, %w[broskies])
    @fluff.ldap = ldap

    assert(@fluff.valid_group?('broskies'))
  end

  def test_invalid_group
    ldap.expect(:group_exists?, false, %w[broskerinos])
    @fluff.ldap = ldap

    refute(@fluff.valid_group?('broskerinos'))
  end

  def test_invalid_user
    ldap.expect(:user_exists?, false, ['johnny rotten'])
    @fluff.ldap = ldap

    refute(@fluff.valid_user?('johnny rotten'))
  end
end
