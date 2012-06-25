require 'net-ldap'

class LdapFluff::Posix::Member

  attr_accessor :groups

  def initialize(groups=[])
    @groups = groups
    @groups||= []
  end

end
