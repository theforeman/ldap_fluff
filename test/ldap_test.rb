# frozen_string_literal: true

require_relative 'ldap_test_helper'

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

  def test_unknown_server_type
    @fluff.ldap.config.server_type = nil
    assert_raises(RuntimeError) { @fluff.send(:create_provider, @fluff.ldap.config) }
  end

  def test_instrument
    md.expect(:instrument, ret = nil) do |event, payload, &blk|
      if event == 'test.ldap_fluff' && payload == {}
        blk.call(payload)
        payload.key?(:result)
      end
    end
    @fluff.instrumentation_service = md

    ldap.expect(:open, ret)
    @fluff.ldap.ldap = ldap

    assert_nil @fluff.test
  end

  def test_user_list
    ldap.expect(:users_for_gid, %w[john], %w[bros])
    @fluff.ldap = ldap

    assert_equal %w[john], @fluff.user_list('bros')
  end

  def test_found_user
    md.expect(:find_user, user = Object.new, ['john', true])
    @fluff.ldap.member_service = md

    assert_equal user, @fluff.find_user('john', true)
  end

  def test_found_group
    md.expect(:find_group, group = [Object.new], ['bros', nil])
    @fluff.ldap.member_service = md

    assert_equal group, @fluff.find_group('bros')
  end
end
