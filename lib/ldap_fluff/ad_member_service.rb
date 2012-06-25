require 'net/ldap'

class LdapFluff::ActiveDirectory::MemberService

  attr_accessor :ldap
  def initialize(ldap,config={})
    @ldap = ldap
  end

  def find_user(uid)
    name_filter = Net::LDAP::Filter.eq("samaccountname",uid)
    @data = @ldap.search(:filter => name_filter)
    raise UIDNotFoundException if @data == nil
    LdapFluff::ActiveDirectory::Member.new(@ldap,@data.first)
  end

  class UIDNotFoundException < StandardError
  end
end
