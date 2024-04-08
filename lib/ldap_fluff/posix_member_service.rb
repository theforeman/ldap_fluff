require 'net/ldap'

# handles the naughty bits of posix ldap
class LdapFluff::Posix::MemberService < LdapFluff::GenericMemberService
  def initialize(ldap, config)
    @attr_login = (config.attr_login || 'memberuid')
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
    @ldap.search(
      :filter => user_group_filter(uid),
      :base => @group_base, :attributes => ["cn"]
    ).map { |entry| entry[:cn][0] }
  end

  class UIDNotFoundException < LdapFluff::Error
  end

  class GIDNotFoundException < LdapFluff::Error
  end

  private

  def user_group_filter(uid)
    unique_filter = Net::LDAP::Filter.eq('uniquemember', "uid=#{uid},#{@base}") &
                    Net::LDAP::Filter.eq('objectClass', 'groupOfUniqueNames')
    Net::LDAP::Filter.eq('memberuid', uid) | unique_filter
  end
end
