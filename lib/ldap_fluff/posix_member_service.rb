require 'net/ldap'

# handles the naughty bits of posix ldap
class LdapFluff::Posix::MemberService < LdapFluff::GenericMemberService
  def initialize(ldap, config)
    @attr_login = (config.attr_login || 'memberuid')
    super
  end

  def find_user(uid, base_dn = @base)
    user = @ldap.search(:filter => name_filter(uid), :base => base_dn)
    raise UIDNotFoundException if (user.nil? || user.empty?)
    user
  end

  # return an ldap user with groups attached
  # note : this method is not particularly fast for large ldap systems
  def find_user_groups(uid)
    @ldap.search(
      :filter => Net::LDAP::Filter.eq('memberuid', uid),
      :base => @group_base, :attributes => ["cn"]
    ).map { |entry| entry[:cn][0] }
  end

  def times_in_groups(uid, gids, all)
    gids.map { |cn| group_filter(cn) }
    group_filters = merge_filters(filters, all)
    filter        = name_filter(uid) & group_filters
    @ldap.search(:base => @group_base, :filter => filter).size
  end

  # AND or OR all of the filters together
  def merge_filters(filters = [], all = false)
    if all
      filters&.reduce(:&)
    else
      filters&.reduce(:|)
    end
  end

  class UIDNotFoundException < LdapFluff::Error
  end

  class GIDNotFoundException < LdapFluff::Error
  end
end
