class LdapFluff::Posix

  attr_accessor :ldap, :member_service

  def initialize(config={})
    @ldap           = Net::LDAP.new :host       => config.host,
                                    :base       => config.base_dn,
                                    :port       => config.port,
                                    :encryption => config.encryption
    @group_base     = config.group_base || config.base
    @base           = config.base_dn
    @member_service = MemberService.new(@ldap, @group_base)
  end

  def bind?(uid=nil, password=nil)
    @ldap.bind_as :filter   => "(uid=#{uid})",
                  :password => password
  end

  def groups_for_uid(uid)
    @member_service.find_user_groups(uid)
  end

  # returns whether a user is a member of ALL or ANY particular groups
  # note: this method is much faster than groups_for_uid
  #
  # gids should be an array of group common names
  #
  # returns true if owner is in ALL of the groups if all=true, otherwise
  # returns true if owner is in ANY of the groups
  def is_in_groups(uid, gids = [], all=true)
    (gids.empty? || @member_service.times_in_groups(uid, gids, all) > 0)
  end

  def user_exists?(uid)
    begin
      user = @member_service.find_user(uid)
    rescue MemberService::UIDNotFoundException
      return false
    end
    return true
  end

  def group_exists?(gid)
    begin
      group = @member_service.find_group(gid)
    rescue MemberService::GIDNotFoundException
      return false
    end
    return true
  end

end
