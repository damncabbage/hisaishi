require 'socket'

module Net
  module IpHelpers

    def local_private_ipv4
      @private_ipv4 ||= Socket.ip_address_list.detect{|intf| intf.ipv4_private?}.try(:ip_address)
    end

    def local_private_or_loopback_ipv4
      @private_or_loopback_ipv4 ||= (local_private_ipv4 || 'localhost')
    end

    def local_public_ipv4
      @public_ipv4 ||= Socket.ip_address_list.detect do |intf|
        intf.ipv4? and !intf.ipv4_loopback? and !intf.ipv4_multicast? and !intf.ipv4_private?
      end.try(:ip_address)
    end

  end
end
