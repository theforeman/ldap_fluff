# frozen_string_literal: true

# @abstract
class LdapFluff::Generic
  # @!attribute [rw] ldap
  #   @return [Net::LDAP]
  # @!attribute [rw] member_service
  #   @return [GenericMemberService]
  attr_accessor :ldap, :member_service

  # @return [Config]
  attr_reader :config

  # @param [Config] config
  def initialize(config)
    @config = config

    @ldap           = create_ldap_client(config)
    @member_service = create_member_service(config)
  end

  # @param [String] uid
  # @return [Boolean]
  def user_exists?(uid)
    service_bind
    member_service.find_user(uid)
    true
  rescue self.class::MemberService::UIDNotFoundException
    false
  end

  # @param [String] gid
  # @return [Boolean]
  def group_exists?(gid)
    service_bind
    member_service.find_group(gid)
    true
  rescue self.class::MemberService::GIDNotFoundException
    false
  end

  # @param [String] uid
  # @return [Array<String>]
  def groups_for_uid(uid)
    service_bind
    member_service.find_user_groups(uid)
  rescue self.class::MemberService::UIDNotFoundException
    []
  end

  # @param [String] gid
  # @return [Array<String>]
  def users_for_gid(gid)
    return [] unless group_exists?(gid)

    search = member_service.find_group(gid, false)
    method = select_member_method(search)

    method ? users_from_search_results(search, method) : []
  end

  # returns whether a user is a member of ALL or ANY particular groups
  # @note this method is much faster than groups_for_uid
  #
  # @param [String] uid
  # @param [Array<String>] gids should be an array of group common names
  # @return [Boolean]
  #   returns true if owner is in ALL of the groups if all=true, otherwise
  #   returns true if owner is in ANY of the groups
  def user_in_groups?(uid, gids = [], all = true)
    service_bind
    return true if !gids || gids.empty?

    groups = member_service.find_user_groups(uid)
    intersection = gids & (groups || [])

    all ? (intersection.sort == gids.sort) : !intersection.empty?
  end

  # @param [String] cn
  # @return [Boolean]
  def includes_cn?(cn)
    filter = Net::LDAP::Filter.eq('cn', cn)
    result = ldap.search(base: ldap.base, filter: filter)
    # NOTE: present?
    !(result.respond_to?(:empty?) ? result.empty? : !result)
  end

  # @raise [UnauthenticatedException]
  def service_bind
    return if config.anon_queries || bind?(config.service_user, config.service_pass, search: false)

    raise UnauthenticatedException, "Could not bind to #{class_name} user #{config.service_user}"
  end

  # @param [String] uid
  # @param [String] password
  # @return [Boolean]
  # @abstract
  def bind?(uid = nil, password = nil, _ = {})
    ldap.auth(uid, password)
    ldap.bind
  end

  private

  # @param [Net::LDAP::Entry] search_result
  # @return [Symbol]
  def select_member_method(search_result)
    return nil unless search_result

    if config.use_netgroups
      :nisnetgrouptriple
    else
      [:member, :memberuid, :uniquemember].find { |m| search_result.respond_to? m }
    end
  end

  # @param [Config] config
  # @return [Net::LDAP]
  def create_ldap_client(config)
    Net::LDAP.new(
      host: config.host,
      port: config.port,
      base: config.base_dn,
      encryption: config.encryption,
      instrumentation_service: config.instrumentation_service
    )
  end

  # @param [Config] config
  # @return [GenericMemberService]
  def create_member_service(config)
    if config.use_netgroups
      self.class::NetgroupMemberService.new(@ldap, config)
    else
      self.class::MemberService.new(@ldap, config)
    end
  end

  # @return [String]
  def class_name
    self.class.name.split('::').last
  end

  # @param [Net::LDAP::Entry] search
  # @param [Symbol] method
  # @return [Array<String>]
  # @abstract
  def users_from_search_results(search, method)
    raise NotImplementedError, "#{search.inspect}, #{method.inspect}"
  end

  class UnauthenticatedException < LdapFluff::Error
  end
end
