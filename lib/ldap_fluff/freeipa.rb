# frozen_string_literal: true

class LdapFluff::FreeIPA < LdapFluff::Generic
  # @param [String] uid
  # @param [String] password
  # @param [Hash] opts
  # @return [Boolean]
  def bind?(uid = nil, password = nil, opts = {})
    unless !uid || uid.include?(',')
      user =
        if opts[:search] != false
          service_bind
          member_service.find_user(uid, true)
        end

      uid = user ? user.dn : "uid=#{uid},cn=users,cn=accounts,#{config.base_dn}"
    end

    super(uid, password)
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
    type = member.downcase.split(',')[1]

    if type == 'cn=users'
      member_service.get_logins([member])
    elsif type == 'cn=groups'
      users_for_gid(member.split(',').first.split('=')[1])
    end
  end
end
