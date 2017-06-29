require 'net/ldap'

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
    user.delete_if { |u| u.nil? || !u.respond_to?(:attribute_names) || !u.attribute_names.include?(:memberof) }
    raise InsufficientQueryPrivilegesException if user.size < 1
    get_groups(user[0][:memberof])
  end

  # extract the group names from the LDAP style response,
  # return string will be something like
  # CN=bros,OU=bropeeps,DC=jomara,DC=redhat,DC=com
  def get_groups(grouplist)
    grouplist.map(&:downcase).collect do |g|
      if g.match(/.*?ipauniqueid=(.*?)/)
        @ldap.search(:base => g)[0][:cn][0]
      else
        g.sub(/.*?cn=(.*?),.*/, '\1')
      end
    end.compact
  end

  class UIDNotFoundException < LdapFluff::Error
  end

  class GIDNotFoundException < LdapFluff::Error
  end

  class InsufficientQueryPrivilegesException < LdapFluff::Error
  end

end

