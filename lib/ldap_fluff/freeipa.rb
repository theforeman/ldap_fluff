class LdapFluff::FreeIPA

  attr_accessor :ldap, :member_service

  def initialize(config={})
    @ldap = Net::LDAP.new :host => config.host,
                         :base => config.base_dn,
                         :port => config.port,
                         :encryption => config.encryption
    @group_base = config.group_base
    @group_base ||= config.base
    @base = config.base_dn
    @bind_user = config.service_user
    @bind_pass = config.service_pass
    @anon = config.anon_queries

    @member_service = MemberService.new(@ldap,@group_base)
  end

  def bind?(uid=nil, password=nil)
    @ldap.auth "uid=#{uid},cn=users,cn=accounts,#{@base}", password
    @ldap.bind
  end

  def groups_for_uid(uid)
    service_bind
    begin
      @member_service.find_user_groups(uid)
    rescue MemberService::UIDNotFoundException
      return []
    rescue MemberService::InsufficientQueryPrivilegesException
      raise UnauthenticatedFreeIPAException, "Insufficient Privileges to query groups data"
    end
  end

  # AD generally does not support un-authenticated searching
  # Typically AD admins configure a public user for searching
  def service_bind
    unless @anon || bind?(@bind_user, @bind_pass)
      raise UnauthenticatedFreeIPAException, "Could not bind to FreeIPA Query User"
    end
  end

  # In freeipa, a simple user query returns a full set
  # of nested groups! yipee
  #
  # gids should be an array of group common names
  #
  # returns true if owner is in ALL of the groups if all=true, otherwise
  # returns true if owner is in ANY of the groups
  def is_in_groups(uid, gids = [], all=true)
    service_bind
    groups = @member_service.find_user_groups(uid)
    if all
      return groups & gids == gids
    else
      return groups & gids != []
    end
  end

  class UnauthenticatedFreeIPAException < StandardError
  end

end

