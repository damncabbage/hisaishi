Hisaishi.controllers :player do
  disable :layout

  # /player
  get :index do
    render 'player/index'
  end

end
