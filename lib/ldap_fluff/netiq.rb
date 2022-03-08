class LdapFluff::NetIQ < LdapFluff::Posix
  def create_member_service(config)
    service_bind
    super(config)
  end
end
