require 'net/ldap'

class LdapFluff::GenericMemberService
  attr_accessor :ldap

  def initialize(ldap, config)
    @ldap       = ldap
    @base       = config.base_dn
    @group_base = (config.group_base.empty? ? config.base_dn : config.group_base)
    @search_filter = nil
    begin
      @search_filter = Net::LDAP::Filter.construct(config.search_filter) unless (config.search_filter.nil? || config.search_filter.empty?)
    rescue Net::LDAP::Error => e
      puts "Search filter unavailable - #{e}"
    end
  end

  def find_user(uid)
    user = @ldap.search(:filter => name_filter(uid))
    raise self.class::UIDNotFoundException if (user.nil? || user.empty?)
    user
  end

  def find_by_dn(dn)
    user = @ldap.search(:base => dn, :scope => Net::LDAP::SearchScope_BaseObject)
    raise self.class::UIDNotFoundException if (user.nil? || user.empty?)
    user
  end

  def find_group(gid)
    group = @ldap.search(:filter => group_filter(gid), :base => @group_base)
    raise self.class::GIDNotFoundException if (group.nil? || group.empty?)
    group
  end

  def name_filter(uid, attr = @attr_login)
    filter = Net::LDAP::Filter.eq(attr, uid)

    if @search_filter.nil?
      filter
    else
      filter & @search_filter
    end
  end

  def group_filter(gid)
    Net::LDAP::Filter.eq("cn", gid)
  end

  # extract the group names from the LDAP style response,
  # return string will be something like
  # CN=bros,OU=bropeeps,DC=jomara,DC=redhat,DC=com
  def get_groups(grouplist)
    grouplist.map(&:downcase).collect { |g| g.sub(/.*?cn=(.*?),.*/, '\1') }
  end

  def get_netgroup_users(netgroup_triples)
    return [] if netgroup_triples.nil?
    netgroup_triples.map { |m| m.split(',')[1] }
  end

  def get_logins(userlist)
    userlist.map(&:downcase!)
    [@attr_login, 'uid', 'cn'].map do |attribute|
      logins = userlist.collect { |g| g.sub(/.*?#{attribute}=(.*?),.*/, '\1') }
      if logins == userlist
        nil
      else
        logins
      end
    end.uniq.compact.flatten
  end

  def get_login_from_entry(entry)
    [@attr_login, 'uid', 'cn'].each do |attribute|
      return entry.send(attribute) if entry.respond_to? attribute
    end
    nil
  end
end
