require 'net/ldap'

# handles the naughty bits of posix ldap
class LdapFluff::FreeIPA::MemberService

  attr_accessor :ldap

  def initialize(ldap,group_base)
    @ldap = ldap
    @group_base = group_base
  end

  # return an ldap user with groups attached
  # note : this method is not particularly fast for large ldap systems
  def find_user_groups(uid)
    user = find_user(uid)
    # if group data is missing, they aren't querying with a user
    # with enough privileges
    raise InsufficientQueryPrivilegesException if user.size <= 1
    _group_names_from_cn(user[1][:memberof])
  end

  def find_user(uid)
    user = @ldap.search(:filter => name_filter(uid))
    raise UIDNotFoundException if (user == nil || user.empty?)
    user
  end

  def find_group(gid)
    group = @ldap.search(:filter => group_filter(gid), :base => @group_base)
    raise GIDNotFoundException if (group == nil || group.empty?)
    group
  end

  def name_filter(uid)
    Net::LDAP::Filter.eq("uid",uid)
  end

  def group_filter(gid)
    Net::LDAP::Filter.eq("cn",gid)
  end

  def _group_names_from_cn(grouplist)
    p = Proc.new { |g| g.sub(/.*?cn=(.*?),.*/, '\1') }
    grouplist.collect(&p)
  end

  class UIDNotFoundException < StandardError
  end

  class GIDNotFoundException < StandardError
  end

  class InsufficientQueryPrivilegesException < StandardError
  end
end

