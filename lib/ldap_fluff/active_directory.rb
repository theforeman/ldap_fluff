class LdapFluff::ActiveDirectory < LdapFluff::Generic

  def initialize(config = {})
    @bind_user  = config.service_user
    @bind_pass  = config.service_pass
    @anon       = config.anon_queries
    super
  end

  def bind?(uid = nil, password = nil)
    @ldap.auth(uid, password)
    @ldap.bind
  end

  # returns the list of groups to which a user belongs
  # this query is simpler in active directory
  def groups_for_uid(uid)
    service_bind
    super
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

  def user_exists?(uid)
    service_bind
    super
  end

  def group_exists?(gid)
    service_bind
    super
  end

  private

  def users_from_search_results(search, method)
    users = []

    search.send(method).each do |member|
      cn    = member.downcase.split(',')[0].split('=')[1]
      entry = @member_service.find_user(cn).first

      objectclasses = entry.objectclass.map(&:downcase)

      if (%w(organizationalperson person) & objectclasses).present?
        users << @member_service.get_logins([member])
      elsif (%w(organizationalunit group) & objectclasses).present?
        users << users_for_gid(cn)
      end
    end

    users.flatten.uniq
  end

end
