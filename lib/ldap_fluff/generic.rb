# frozen_string_literal: true

# @abstract
class LdapFluff::Generic
  # @!attribute [rw] ldap
  #   @return [Net::LDAP]
  # @!attribute [rw] member_service
  #   @return [LdapFluff::GenericMemberService]
  attr_accessor :ldap, :member_service

  # @return [LdapFluff::Config]
  attr_reader :config

  # @param [LdapFluff::Config] config
  def initialize(config)
    @config     = config
    @is_bind_dn = /(?<!\\),/

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
    service_bind
    begin
      # @type [Net::LDAP::Entry]
      search = member_service.find_group(gid, false)
    rescue self.class::MemberService::GIDNotFoundException
      return []
    end

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
  # @deprecated
  def includes_cn?(cn)
    service_bind
    search = ldap.search(filter: Net::LDAP::Filter.eq('cn', cn))
    # NOTE: present?
    !(search.respond_to?(:empty?) ? search.empty? : !search)
  end

  # @raise [UnauthenticatedException]
  def service_bind
    return if config.anon_queries || bind?(config.service_user, config.service_pass, search: false)

    raise UnauthenticatedException, "Could not bind to #{class_name} user #{config.service_user}"
  end

  # @param [String] uid
  # @param [String] password
  # @param [Hash] opts
  # @return [Boolean]
  def bind?(uid = nil, password = nil, opts = {})
    uid = get_bind_dn(uid, opts) if uid && !@is_bind_dn.match(uid)

    ldap.auth(uid, password)
    ldap.bind
  end

  private

  # @param [String] uid
  # @param [Hash] opts
  # @return [String]
  def get_bind_dn(uid, opts = {})
    user =
      if opts[:search] != false && uid != config.service_user
        service_bind
        member_service.find_user(uid, true)
      end

    user ? user.dn : format(config.bind_dn_format, uid)
  end

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

  # @param [LdapFluff::Config] config
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

  # @param [LdapFluff::Config] config
  # @return [LdapFluff::GenericMemberService]
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
