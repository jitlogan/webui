class Yxorp3
  class Tunnel
    def initialize
      tunnels = File.read('/usr/local/3proxy/conf/tunnels')
      unless tunnels.match(/socks/)
        @tunnels = []
        return @tunnels
      end
      @tunnels = tunnels.split(/flush/).map(&:strip).map do |entry|
        entry.split("\n")
      end.map do |entry|
        {username: entry.first.split.last, tunnel: entry.last}
      end.each do |entry|
        tunnel_parsed = {}
        entry[:tunnel].split.each do |tun_param|
          case tun_param
          when /^socks/
            tunnel_parsed[:type] = tun_param
          when /^-i/
            tunnel_parsed[:inbound] = tun_param.delete('-i')
          when /^-e/
            tunnel_parsed[:outbound] = tun_param.delete('-e')
          when /^-p/
            tunnel_parsed[:port] = tun_param.delete('-p')
          end
          entry[:tunnel_parsed] = tunnel_parsed
        end
      end
    end
    
    def list_tunnels
      @tunnels.map do |tunnel|
        { username: tunnel[:username]}.merge tunnel[:tunnel_parsed]
      end
    end

    def add_tunnel(type, inbound, outbound, user, port)
      @tunnels << {username: user, type: 'socks5', inbound: inbound, outbound: outbound, port: port, tunnel: "#{type} -i#{inbound} -e#{outbound} -p#{port}"}
    end

    def delete_tunnel(id)
      @tunnels.delete(@tunnels[id.to_i - 1])
    end

    def save
      require 'stringio'
      data = StringIO.new
      @tunnels.each_with_index do |tunnel, index|
        data.write("flush\n") unless index.eql?(0)
        data.write("allow #{tunnel[:username]}\n")
        data.write("#{tunnel[:tunnel]}\n")
      end
      File.open('/usr/local/3proxy/conf/tunnels', 'w') do |file|
        data.rewind
        file.puts(data.read)
      end
    end

  end
end
