class LdapFluff::Generic
  attr_accessor :ldap, :member_service

  def initialize(config = {})
    @ldap = Net::LDAP.new(:host => config.host,
                          :base => config.base_dn,
                          :port => config.port,
                          :encryption => config.encryption,
                          :instrumentation_service => config.instrumentation_service)
    @bind_user = config.service_user
    @bind_pass = config.service_pass
    @anon = config.anon_queries
    @attr_login = config.attr_login
    @base       = config.base_dn
    @group_base = (config.group_base.empty? ? config.base_dn : config.group_base)
    @use_netgroups = config.use_netgroups
    @use_rfc4519_group_membership = config.use_rfc4519_group_membership
    @member_service = create_member_service(config)
  end

  def user_exists?(uid)
    service_bind
    @member_service.find_user(uid)
    true
  rescue self.class::MemberService::UIDNotFoundException
    false
  end

  def group_exists?(gid)
    service_bind
    @member_service.find_group(gid)
    true
  rescue self.class::MemberService::GIDNotFoundException
    false
  end

  def groups_for_uid(uid)
    service_bind
    @member_service.find_user_groups(uid)
  rescue self.class::MemberService::UIDNotFoundException
    []
  end

  def users_for_gid(gid)
    return [] unless group_exists?(gid)
    search = @member_service.find_group(gid).last
    method = select_member_method(search)
    return [] if method.nil?
    users_from_search_results(search, method)
  end

  # returns whether a user is a member of ALL or ANY particular groups
  # note: this method is much faster than groups_for_uid
  #
  # gids should be an array of group common names
  #
  # returns true if owner is in ALL of the groups if all=true, otherwise
  # returns true if owner is in ANY of the groups
  def is_in_groups(uid, gids = [], all = true)
    service_bind
    groups = @member_service.find_user_groups(uid).sort
    gids = gids.sort
    if all
      groups & gids == gids
    else
      (groups & gids).any?
    end
  end

  def includes_cn?(cn)
    filter = Net::LDAP::Filter.eq('cn', cn)
    @ldap.search(:base => @ldap.base, :filter => filter).present?
  end

  def service_bind
    unless @anon || bind?(@bind_user, @bind_pass, :search => false)
      raise UnauthenticatedException,
        "Could not bind to #{class_name} user #{@bind_user}"
    end
  end

  private

  def select_member_method(search_result)
    if @use_netgroups
      :nisnetgrouptriple
    else
      %i[member memberuid uniquemember].find { |m| search_result.respond_to? m }
    end
  end

  def create_member_service(config)
    if @use_netgroups
      self.class::NetgroupMemberService.new(@ldap, config)
    else
      self.class::MemberService.new(@ldap, config)
    end
  end

  def class_name
    self.class.name.split('::').last
  end

  def users_from_search_results(search, method)
    members = search.send method
    if method == :memberuid
      # memberuid contains an array ['user1','user2'], no need to parse it
      members
    elsif method == :nisnetgrouptriple
      @member_service.get_netgroup_users(members)
    else
      @member_service.get_logins(members)
    end
  end

  class UnauthenticatedException < LdapFluff::Error
  end
end
