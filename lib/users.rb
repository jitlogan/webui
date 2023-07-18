class Yxorp3
    class Users
        require 'unix_crypt'

        USR_RE = /(?<full>(?<username>\w+):CR:(?<hash>\$1\$(?<salt>\d+)\$.+$))/

        def initialize
            @users = []
            File.read('/usr/local/3proxy/conf/passwd').split.each do |entry|
                parsed_data = entry.match(USR_RE)
                @users << {username: parsed_data['username'], full: parsed_data['full'], salt: parsed_data['salt'], hash: parsed_data['hash']}
            end
        end

        def delete_user(username)
            @users.delete(@users.find{|entry| entry[:username] == username})
        end

        def add_user(username, password)
            raise RuntimeError, 'Duplicate user' if check_duplicate(username)
            salt = create_next_salt
            hash = UnixCrypt::MD5.build(password, salt)
            full = "#{username}:CR:#{hash}"
            @users << {username: username, full: full, salt: salt, hash: hash}
        end

        def list_users
            @users.map{|entry| entry[:username]}
        end

        def save
            File.open('/usr/local/3proxy/conf/passwd', 'w') do |file|
                file.write(@users.map{|entry| entry[:full]}.join("\n") + "\n")
            end
        end



        private
            def create_next_salt
                if @users.empty?
                  salt = Random.rand(1000..3000).to_s
                else
                  salt = @users.max{|entry| entry[:salt].to_i}[:salt].to_i
                  salt += 1
                  salt.to_s
                end
            end

            def check_duplicate(username)
                @users.any? do |entry|
                    entry[:username] == username
                end
            end
    end
end
