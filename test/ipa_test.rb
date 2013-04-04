require_relative './lib/ldap_test_helper'

class TestIPA < MiniTest::Unit::TestCase
  include LdapTestHelper

  def setup
    config
    @ipa = LdapFluff::FreeIPA.new(@config)
    @ldap = MiniTest::Mock.new
  end

  # default setup for service bind users
  def service_bind
    @ldap.expect(:auth, nil, [ipa_user_bind('service'),"pass"])
    @ldap.expect(:bind, true)
    @ipa.ldap = @ldap
  end

  def basic_user
    @md = MiniTest::Mock.new
    @md.expect(:find_user_groups, ['bros'], ["john"])
    @ipa.member_service = @md
  end

  def bigtime_user
    @md = MiniTest::Mock.new
    @md.expect(:find_user_groups, ['bros','broskies'], ["john"])
    @ipa.member_service = @md
  end

  def test_good_bind
    @ldap.expect(:auth, nil, [ipa_user_bind('internet'),"password"])
    @ldap.expect(:bind, true)
    @ipa.ldap = @ldap
    assert_equal @ipa.bind?("internet", "password"), true
    @ldap.verify
  end

  def test_bad_bind
    @ldap.expect(:auth, nil, [ipa_user_bind('internet'),"password"])
    @ldap.expect(:bind, false)
    @ipa.ldap = @ldap
    assert_equal @ipa.bind?("internet", "password"), false
    @ldap.verify
  end

  def test_groups
    service_bind
    basic_user
    assert_equal @ipa.groups_for_uid('john'), ['bros']
  end

  def test_bad_user
    service_bind
    @md = MiniTest::Mock.new
    @md.expect(:find_user_groups, nil, ["john"])
    def @md.find_user_groups(*args)
      raise LdapFluff::FreeIPA::MemberService::UIDNotFoundException
    end
    @ipa.member_service = @md
    assert_equal @ipa.groups_for_uid('john'), []
  end

  def test_bad_service_user
    @ldap.expect(:auth, nil, [ipa_user_bind('service'),"pass"])
    @ldap.expect(:bind, false)
    @ipa.ldap = @ldap
    assert_raises(LdapFluff::FreeIPA::UnauthenticatedFreeIPAException) { @ipa.groups_for_uid('john') }
  end

  def test_is_in_groups
    service_bind
    basic_user
    assert_equal @ipa.is_in_groups("john",["bros"],false), true
  end

  def test_is_some_groups
    service_bind
    basic_user
    assert_equal @ipa.is_in_groups("john",["bros","buds"],false), true
  end

  def test_isnt_in_all_groups
    service_bind
    basic_user
    assert_equal @ipa.is_in_groups("john",["bros","buds"],true), false
  end

  def test_isnt_in_groups
    service_bind
    basic_user
    assert_equal @ipa.is_in_groups("john", ["broskies"],false), false
  end

  def test_group_subset
    service_bind
    bigtime_user
    assert_equal @ipa.is_in_groups('john',["broskies"],true), true
  end

  def test_user_exists
    @md = MiniTest::Mock.new
    @md.expect(:find_user, 'notnilluser', ["john"])
    @ipa.member_service = @md
    service_bind
    assert @ipa.user_exists?('john')
  end

  def test_missing_user
    @md = MiniTest::Mock.new
    @md.expect(:find_user, nil, ['john'])
    def @md.find_user uid
      raise LdapFluff::FreeIPA::MemberService::UIDNotFoundException
    end
    @ipa.member_service = @md
    service_bind
    assert !@ipa.user_exists?('john')
  end

  def test_group_exists
    @md = MiniTest::Mock.new
    @md.expect(:find_group, 'notnillgroup', ["broskies"])
    @ipa.member_service = @md
    service_bind
    assert @ipa.group_exists?('broskies')
  end

  def test_missing_group
    @md = MiniTest::Mock.new
    @md.expect(:find_group, nil, ['broskies'])
    def @md.find_group uid
      raise LdapFluff::FreeIPA::MemberService::GIDNotFoundException
    end
    @ipa.member_service = @md
    service_bind
    assert !@ipa.group_exists?('broskies')
  end
end

