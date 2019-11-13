# frozen_string_literal: true

class LdapFluff::FreeIPA < LdapFluff::Generic
  def bind?(uid = nil, password = nil, opts = {})
    unless uid.include?(',')
      unless opts[:search] == false
        service_bind
        user = @member_service.find_user(uid)
      end
      uid = user && user.first ? user.first.dn : "uid=#{uid},cn=users,cn=accounts,#{@base}"
    end
    @ldap.auth(uid, password)
    @ldap.bind
  end

  def groups_for_uid(uid)
    begin
      super
    rescue MemberService::InsufficientQueryPrivilegesException
      raise UnauthenticatedException, 'Insufficient Privileges to query groups data'
    end
  end

  private

  def users_from_search_results(search, method)
    # Member results come in the form uid=sampleuser,cn=users, etc.. or gid=samplegroup,cn=groups
    users = []

    members = search.send(method)

    if method == :nisnetgrouptriple
      users = @member_service.get_netgroup_users(members)
    else
      members.each do |member|
        type = member.downcase.split(',')[1]
        if type == 'cn=users'
          users << @member_service.get_logins([member])
        elsif type == 'cn=groups'
          users << users_for_gid(member.split(',')[0].split('=')[1])
        end
      end
    end

    users.flatten.uniq
  end
end
