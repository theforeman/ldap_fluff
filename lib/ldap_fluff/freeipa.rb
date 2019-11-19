# frozen_string_literal: true

class LdapFluff::FreeIPA < LdapFluff::Generic
  # @param [LdapFluff::Config] config
  def initialize(config)
    config.bind_dn_format ||= "uid=%s,cn=users,cn=accounts,#{config.base_dn}"
    super
  end

  # @param [String] uid
  # @return [Array<String>]
  # @raise [UnauthenticatedException]
  def groups_for_uid(uid)
    super
  rescue MemberService::InsufficientQueryPrivilegesException
    raise UnauthenticatedException, 'Insufficient Privileges to query groups data'
  end

  private

  # Member results come in the form uid=sampleuser,cn=users, etc.. or gid=samplegroup,cn=groups
  # @param [Net::LDAP::Entry] search
  # @param [Symbol] method
  # @return [Array<String>]
  def users_from_search_results(search, method)
    members = search.send method

    # @type [Array<String>]
    users =
      if method == :nisnetgrouptriple
        member_service.get_netgroup_users(members)
      else
        members.map { |member| get_users_for_member(member) }
      end

    users.flatten.compact.uniq
  end

  # @param [String] member DN
  # @return [Array<String>, String]
  def get_users_for_member(member)
    if member =~ /,(cn|ou)=users(,|$)/i
      member_service.get_logins([member])
    elsif member =~ /,(cn|ou)=groups(,|$)/i
      users_for_gid(member.sub(/^.*?=([^,]*).*/, '\1'))
    end
  end
end
