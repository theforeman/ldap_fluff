class LdapFluff::ActiveDirectory < LdapFluff::Generic

  def bind?(uid = nil, password = nil, opts = {})
    unless uid.include?(',') || uid.include?('\\') || opts[:search] == false
      service_bind
      user = @member_service.find_user(uid)
      uid = user.first.dn if user && user.first
    end
    @ldap.auth(uid, password)
    @ldap.bind
  end

  # active directory stores group membership on a users model
  # TODO: query by group individually not like this
  def is_in_groups(uid, gids = [], all = false)
    service_bind
    return true if gids == []
    begin
      groups       = @member_service.find_user_groups(uid)
      intersection = gids & groups
      return (all ? intersection == gids : intersection.size > 0)
    rescue MemberService::UIDNotFoundException
      return false
    end
  end

  private

  def users_from_search_results(search, method)
    users = []

    search.send(method).each do |member|
      entry = @member_service.find_by_dn(member).first
      objectclasses = entry.objectclass.map(&:downcase)

      if (%w(organizationalperson person userproxy) & objectclasses).present?
        users << @member_service.get_login_from_entry(entry)
      elsif (%w(organizationalunit group) & objectclasses).present?
        users << users_for_gid(entry.cn.first)
      end
    end

    users.flatten.uniq
  end

end
