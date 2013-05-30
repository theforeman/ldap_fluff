require 'yaml'

class LdapFluff
  class Config
    ATTRIBUTES = [:host, :port, :encryption, :base_dn, :group_base, :server_type, :ad_domain, :service_user,
                  :service_pass, :anon_queries]
    ATTRIBUTES.each { |attr| attr_reader attr }

    def initialize(options)
      raise ArgumentError unless options.respond_to?(:to_hash)
      options = options.to_hash.inject({}) { |hash, (k, v)| hash.update k.to_s => v }
      ATTRIBUTES.each { |attr| instance_variable_set :"@#{attr}", options[attr.to_s] }
      @encryption = @encryption.to_sym if @encryption
      @server_type = @server_type.to_sym if @server_type
    end
  end
end
