require 'net/ldap'

# handles the naughty bits of posix ldap
class LdapFluff::FreeIPA::MemberService < LdapFluff::GenericMemberService

  def initialize(ldap, config)
    @attr_login = (config.attr_login || 'uid')
    super
  end

  # return an ldap user with groups attached
  # note : this method is not particularly fast for large ldap systems
  def find_user_groups(uid)
    user = find_user(uid)
    # if group data is missing, they aren't querying with a user
    # with enough privileges
    raise InsufficientQueryPrivilegesException if user.size <= 1
    get_groups(user[1][:memberof])
  end

  class UIDNotFoundException < LdapFluff::Error
  end

  class GIDNotFoundException < LdapFluff::Error
  end

  class InsufficientQueryPrivilegesException < LdapFluff::Error
  end

end

