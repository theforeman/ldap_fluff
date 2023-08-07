require 'lib/ldap_test_helper'

class TestNetIQ < Minitest::Test
  include LdapTestHelper

  def setup
    super
    @ldap.expect(:bind, true)
    @ldap.expect(:auth, nil, %w[service pass])
    Net::LDAP.stub :new, @ldap do
      @netiq = LdapFluff::NetIQ.new(@config)
    end
  end

  def service_bind
    @ldap.expect(:auth, nil, %w[service pass])
    super
  end

  def test_groups
    service_bind
    basic_user
    assert_equal(@netiq.groups_for_uid("john"), %w[bros])
  end

  def test_missing_user
    md = Minitest::Mock.new
    md.expect(:find_user_groups, [], %w[john])
    @netiq.member_service = md
    @ldap.expect(:bind, true)
    @ldap.expect(:auth, nil, %w[service pass])
    assert_equal([], @netiq.groups_for_uid('john'))
  end

  def test_isnt_in_groups
    service_bind
    basic_user
    assert_equal(@netiq.is_in_groups('john', %w[broskies], true), false)
  end

  def test_is_in_groups
    service_bind
    basic_user
    assert_equal(@netiq.is_in_groups('john', %w[bros], true), true)
  end

  def test_is_in_no_groups
    service_bind
    basic_user
    assert_equal(@netiq.is_in_groups('john', [], true), true)
  end

  def test_good_bind
    # looks up the uid's full DN via the service account
    @md = Minitest::Mock.new
    user_result = Minitest::Mock.new
    user_result.expect(:dn, 'uid=internet,dn=example')
    @md.expect(:find_user, [user_result], %w[internet])
    @netiq.member_service = @md
    service_bind
    @ldap.expect(:auth, nil, %w[uid=internet,dn=example password])
    @ldap.expect(:bind, true)
    @netiq.ldap = @ldap
    assert_equal(@netiq.bind?("internet", "password"), true)
  end

  def test_good_bind_with_dn
    # no expectation on the service account
    @ldap.expect(:auth, nil, %w[uid=internet,dn=example password])
    @ldap.expect(:bind, true)
    @netiq.ldap = @ldap
    assert_equal(@netiq.bind?("uid=internet,dn=example", "password"), true)
  end

  def test_bad_bind
    @ldap.expect(:auth, nil, %w[uid=internet,dn=example password])
    @ldap.expect(:bind, false)
    @netiq.ldap = @ldap
    assert_equal(@netiq.bind?("uid=internet,dn=example", "password"), false)
  end

  def test_user_exists
    service_bind
    md = Minitest::Mock.new
    md.expect(:find_user, 'notnilluser', %w[john])
    @netiq.member_service = md
    assert(@netiq.user_exists?('john'))
  end

  def test_user_not_exists
    service_bind
    md = Minitest::Mock.new
    md.expect(:find_user, nil, %w[john])
    def md.find_user(_uid)
      raise LdapFluff::NetIQ::MemberService::UIDNotFoundException
    end
    @netiq.member_service = md
    refute(@netiq.user_exists?('john'))
  end

  def test_group_exists
    service_bind
    md = Minitest::Mock.new
    md.expect(:find_group, 'notnillgroup', %w[broskies])
    @netiq.member_service = md
    assert(@netiq.group_exists?('broskies'))
  end

  def test_missing_group
    service_bind
    md = Minitest::Mock.new
    md.expect(:find_group, nil, %w[broskies])
    def md.find_group(_uid)
      raise LdapFluff::NetIQ::MemberService::GIDNotFoundException
    end
    @netiq.member_service = md
    refute(@netiq.group_exists?('broskies'))
  end

  def test_find_users_in_nested_groups
    service_bind
    group = Net::LDAP::Entry.new('CN=foremaners,DC=example,DC=com')
    group[:memberuid] = ['katellers']
    nested_group = Net::LDAP::Entry.new('CN=katellers,CN=foremaners,DC=example,DC=com')
    nested_group[:memberuid] = ['testuser']

    @ldap.expect(:search,
      [nested_group],
      [{ :base => group.dn,
         :filter => Net::LDAP::Filter.eq('objectClass', 'posixGroup') |
                    Net::LDAP::Filter.eq('objectClass', 'organizationalunit') |
                    Net::LDAP::Filter.eq('objectClass', 'groupOfUniqueNames') |
                    Net::LDAP::Filter.eq('objectClass', 'groupOfNames') }])
    @netiq.ldap = @ldap

    md = Minitest::Mock.new
    2.times { md.expect(:find_group, [group], ['foremaners']) }
    @netiq.member_service = md

    assert_equal @netiq.users_for_gid('foremaners'), ['testuser']

    md.verify
    @ldap.verify
  end
end
