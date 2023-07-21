require 'sinatra'
enable :sessions

not_found do
  '#)?$0'
end

helpers do
  def authenticate!
    unless session[:user_id]
      redirect '/login'
    end
  end
  def get_ifaces_addresses
    require 'json'
    JSON.parse(%x,/usr/local/3proxy/webui/bin/enum_ifaces_and_ips.sh,)
  end
  def get_used_ports
    require 'json'
    JSON.parse(%x,/usr/local/3proxy/webui/bin/enum_used_ports.sh,)
  end
  def get_addresses
    data = get_ifaces_addresses
    addresses = []
    data.each do |entry|
      addresses += entry[entry.keys.first]
    end
    addresses
  end
  def get_users
    require_relative 'lib/users'
    Yxorp3::Users.new.list_users
  end
  def add_user(username, password)
    require_relative 'lib/users'
    users = Yxorp3::Users.new
    users.add_user(username, password)
    users.save
  end
  def delete_user(username)
    require_relative 'lib/users'
    users = Yxorp3::Users.new
    users.delete_user(username)
    users.save
  end
  def get_tunnels
    require_relative 'lib/tunnels'
    @tunnels = Yxorp3::Tunnel.new.list_tunnels
  end
  def get_ports
    tunnels = get_tunnels
    configured_ports = tunnels.map do |tunnel|
      tunnel[:port].to_i
    end
    used_ports = get_used_ports
    (used_ports + configured_ports).uniq  
  end
  def add_tunnel(type, inbound, outbound, user, port)
    require_relative 'lib/tunnels'
    tunnels = Yxorp3::Tunnel.new
    tunnels.add_tunnel(type, inbound, outbound, user, port)
    tunnels.save
  end
  def delete_tunnel(index)
    require_relative 'lib/tunnels'
    tunnels = Yxorp3::Tunnel.new
    tunnels.delete_tunnel(index)
    tunnels.save
  end
  def get_users_in_use
    tunnels = get_tunnels
    tunnels.map do |tunnel|
      tunnel[:username]
    end.uniq
  end
end

get '/login' do
  erb :login, layout: false
end

get '/logout' do
  session.clear
  redirect '/login'
end

post '/login' do
  require 'yaml'
  config = YAML.load_file('config.yml')
  if params[:username].eql?(config['username']) && params[:password].eql?(config['password'])
    session[:user_id] = params[:username]
    redirect '/'
  else
    redirect '/login'
  end
end

get '/tunnels' do
  authenticate!
  @addresses = get_addresses
  @users = get_users
  @tunnels = get_tunnels
  erb :tunnels, locals: {inspect_data: get_used_ports}
end

get '/tdelete/:index' do
  if session[:user_id]
    delete_tunnel(params['index'])
    redirect '/tunnels'
  else
    halt 403, 'Go away!'
  end
end

get '/users' do
  authenticate!
  @users = get_users
  erb :users, locals: {users_in_use: get_users_in_use}
end

post '/user' do
  if session[:user_id]
    add_user(params[:new_user_username], params[:new_user_password])
    redirect '/users'
  else
    halt 403, 'Go away!'
  end
end

post '/tunnel' do
  if session[:user_id]
    unless get_ports.any?{|used_port| used_port.eql?(params[:port].to_i)}
      if params[:port].to_i <= 1024
        halt 403, "The port value must be greater then 1024."
      end
      add_tunnel(params['tunnel-type'], params['inbound'], params['outbound'], params['tunnel_user'], params[:port])
      redirect '/tunnels'
    else
      halt 403, "Port #{params[:port]} is allready in use"
    end
  else
    halt 403, 'Go away!'
  end
end

get "/delete/:user" do
  if session[:user_id]
    users_in_use = get_users_in_use
    unless users_in_use.any?{|user_in_use| user_in_use.eql?(params['user'])}
      delete_user(params['user'])
      redirect '/users'
    else
      halt 403, 'Go away'
    end
  else
    halt 403, 'Go away'
  end
end

get '/' do
  authenticate!
  @iface_data = get_ifaces_addresses
  @users = get_users
  @tunnels = get_tunnels
  erb :index
end
