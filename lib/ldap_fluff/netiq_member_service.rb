require 'net/ldap'

# handles the naughty bits of posix ldap
class LdapFluff::NetIQ::MemberService < LdapFluff::Posix::MemberService
  def initialize(ldap, config)
    super
    # set default after super, because Posix' initialize would overwrite it otherwise
    @attr_login = (config.attr_login || 'uid')
  end

  def find_by_dn(search_dn)
    entry, base = search_dn.split(/(?<!\\),/, 2)
    _entry_attr, entry_value = entry.split('=', 2)
    entry_value = entry_value.gsub('\,', ',')
    user = @ldap.search(:filter => name_filter(entry_value, 'workforceid'), :base => base)
    raise self.class::UIDNotFoundException if (user.nil? || user.empty?)
    user
  end

  def get_logins(userlist)
    userlist.map do |current_user|
      find_by_dn(current_user&.downcase)[0][@attr_login][0]
    end
  end

  # return an ldap user with groups attached
  # note : this method is not particularly fast for large ldap systems
  def find_user_groups(uid)
    filter = Net::LDAP::Filter.eq('memberuid', uid)
    begin
      user = find_user(uid)[0][:dn][0]
      filter |= Net::LDAP::Filter.eq('member', user)
    rescue UIDNotFoundException
      # do nothing
    end

    @ldap.search(
      :filter => filter,
      :base => @group_base,
      :attributes => ['cn']
    ).map { |entry| entry[:cn][0] }
  end
end
