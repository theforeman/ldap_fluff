# frozen_string_literal: true

class LdapFluff::ActiveDirectory < LdapFluff::Generic
  # @param [String] uid
  # @param [String] password
  # @param [Hash] opts
  # @return [Boolean]
  def bind?(uid = nil, password = nil, opts = {})
    if opts[:search] != false && uid && !(uid.include?(',') || uid.include?('\\'))
      service_bind
      user = member_service.find_user(uid, true)

      uid = user.dn if user
    end

    super(uid, password)
  end

  # active directory stores group membership on a users model
  # TODO: query by group individually not like this
  #
  # @param [String] uid
  # @param [Array<String>] gids
  # @return [Boolean]
  def user_in_groups?(uid, gids = [], all = false)
    super
  rescue MemberService::UIDNotFoundException
    false
  end

  private

  # @param [Net::LDAP::Entry] search
  # @param [Symbol] method
  # @return [Array<String>]
  def users_from_search_results(search, method)
    members = search.send method

    # @type [Array<String>]
    users = members.map do |member|
      begin
        entry = member_service.find_by_dn(member, true)
      rescue MemberService::UIDNotFoundException
        entry = nil
      end

      entry ? get_users_for_entry(entry) : nil
    end

    users.flatten.compact.uniq
  end

  # @param [Net::LDAP::Entry] entry
  # @return [Array<String>, String]
  def get_users_for_entry(entry)
    objectclasses = entry[:objectclass].map(&:downcase)

    if !(%w[organizationalperson person userproxy] & objectclasses).empty?
      member_service.get_login_from_entry(entry)
    elsif !(%w[organizationalunit group] & objectclasses).empty?
      users_for_gid(entry[:cn].first)
    end
  end
end
