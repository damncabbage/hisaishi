module HostHelpers

  def self.my_first_non_loopback_ipv4
    addr = Socket.ip_address_list.detect{|intf| intf.ipv4? and !intf.ipv4_loopback? and !intf.ipv4_multicast?}
    @my_first_non_loopback_ipv4 ||= addr.ip_address if addr
  end

  def self.hostname
    @hostname ||= `hostname`
  end

end
