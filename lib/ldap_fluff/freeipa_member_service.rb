# frozen_string_literal: true

class LdapFluff::FreeIPA::MemberService < LdapFluff::GenericMemberService
  # @param [Net::LDAP] ldap
  # @param [Config] config
  def initialize(ldap, config)
    @attr_login = (config.attr_login || 'uid')
    super
  end

  # @param [String] uid
  # @return [Array<String>] an LDAP user with groups attached
  # @note this method is not particularly fast for large LDAP systems
  def find_user_groups(uid)
    user = find_user(uid)

    # if group data is missing, they aren't querying with a user with enough privileges
    user.delete_if { |u| u.nil? || !u.respond_to?(:attribute_names) || !u.attribute_names.include?(:memberof) }
    raise InsufficientQueryPrivilegesException if user.size < 1

    get_groups(user[0][:memberof])
  end

  # extract the group names from the LDAP style response,
  # @param [Array<String>] grouplist
  # @return [Array<String>] will be something like CN=bros,OU=bropeeps,DC=jomara,DC=redhat,DC=com
  def get_groups(grouplist)
    grouplist.map(&:downcase).collect do |g|
      if g.match(/.*?ipauniqueid=(.*?)/)
        @ldap.search(base: g)[0][:cn][0]
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
