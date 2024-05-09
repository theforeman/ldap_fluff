require 'net/ldap'

# handles the naughty bits of posix ldap
class LdapFluff::Posix::MemberService < LdapFluff::GenericMemberService
  def initialize(ldap, config)
    @attr_login = (config.attr_login || 'memberuid')
    @use_rfc4519_group_membership = config.use_rfc4519_group_membership
    super
  end

  def find_user(uid, base_dn = @base)
    user = @ldap.search(:filter => name_filter(uid), :base => base_dn)
    raise UIDNotFoundException if (user.nil? || user.empty?)
    user
  end

  # return an ldap user with groups attached
  # note : this method is not particularly fast for large ldap systems
  def find_user_groups(uid)
    user = find_user(uid).first
    @ldap.search(
      :filter => user_group_filter(uid, user[:dn].first),
      :base => @group_base, :attributes => ["cn"]
    ).map { |entry| entry[:cn][0] }
  end

  class UIDNotFoundException < LdapFluff::Error
  end

  class GIDNotFoundException < LdapFluff::Error
  end

  private

  def user_group_filter(uid, user_dn)
    by_member = Net::LDAP::Filter.eq('memberuid', uid)
    return by_member unless @use_rfc4519_group_membership

    by_name = Net::LDAP::Filter.eq('member', user_dn) &
              Net::LDAP::Filter.eq('objectClass', 'groupOfNames')
    by_unique_name = Net::LDAP::Filter.eq('uniquemember', user_dn) &
                     Net::LDAP::Filter.eq('objectClass', 'groupOfUniqueNames')
    by_member | by_name | by_unique_name
  end
end
