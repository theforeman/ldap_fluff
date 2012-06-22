require 'net-ldap'

class LdapFluff::ActiveDirectory::MemberService

  def initialize(ldap,config={})
    @ldap = ldap
  end

  def find_user(uid)
    name_filter = Net::LDAP::Filter.eq("samaccountname",uid)
    @data = @ldap.search(:filter => @name_filter)
    raise UIDNotFoundException if @data == nil
    LdapFluff::ActiveDirectory::Member.new(@ldap,@data)
  end

  class UIDNotFoundException < StandardError
  end
end
