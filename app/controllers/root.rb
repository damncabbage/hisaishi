Hisaishi.controllers do
  disable :layout

  # /
  get :index do
    # Choose Player or Controller
    @app_url = "http://#{HostHelpers.my_first_non_loopback_ipv4}:#{settings.port}/"
    render 'root/index'
  end

end
