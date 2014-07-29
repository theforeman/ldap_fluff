class LdapFluff::FreeIPA < LdapFluff::Generic

  def initialize(config = {})
    @base       = config.base_dn
    @bind_user  = config.service_user
    @bind_pass  = config.service_pass
    @anon       = config.anon_queries
    super
  end

  def bind?(uid = nil, password = nil)
    @ldap.auth("uid=#{uid},cn=users,cn=accounts,#{@base}", password)
    @ldap.bind
  end

  def groups_for_uid(uid)
    begin
    service_bind
    super
    rescue MemberService::InsufficientQueryPrivilegesException
      raise UnauthenticatedException, "Insufficient Privileges to query groups data"
    end
  end

  # In freeipa, a simple user query returns a full set
  # of nested groups! yipee
  #
  # gids should be an array of group common names
  #
  # returns true if owner is in ALL of the groups if all=true, otherwise
  # returns true if owner is in ANY of the groups
  def is_in_groups(uid, gids = [], all = true)
    service_bind
    groups = @member_service.find_user_groups(uid)
    if all
      return groups & gids == gids
    else
      return groups & gids != []
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
    # Member results come in the form uid=sampleuser,cn=users, etc.. or gid=samplegroup,cn=groups
    users = []

    search.send(method).each do |member|
      type = member.downcase.split(',')[1]
      if type == 'cn=users'
        users << @member_service.get_logins([member])
      elsif type == 'cn=groups'
        users << users_for_gid(member.split(',')[0].split('=')[1])
      end
    end

    users.flatten.uniq
  end
end
