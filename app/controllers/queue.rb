Hisaishi.controllers :queue do
  before do
    # TODO: pin_auth! + redirect url(:controller, :lock)
  end

  # /queue, /queue.json, /queue/index
  get :index, :provides => [:json, :html] do
    @queue_items = QueueItem.ordered.includes(:song).all
    @songs_by_id = @queue_items.inject({}) do |hash,item|
      hash[item.song.id] = item.song
      hash
    end
    render 'queue/index'
  end

  get :add, :map => '/queue/add/:song_id' do
    @song = Song.find(params[:song_id])
    render 'queue/add'
  end

  post :add, :map => '/queue/add/:song_id' do
    @song = Song.find(params[:song_id])
    @queue_item = @song.enqueue(params[:requester])
    send_to_sockets("queue_update", "player", "add", :song_id => params[:song_id])
    render 'queue/add_success'
  end

  get :show, :map => '/queue/:id' do
    # Pop-up dialog with actions per song.
    @queue_item = QueueItem.includes(:song).find(params[:id])
    render 'queue/show'
  end

  post :delete, :map => '/queue/:id/delete' do
    QueueItem.find(params[:id]).destroy
    send_to_sockets("queue_update", "player", "delete", :queue_id => params[:id])
    redirect url(:queue, :index)
  end

  post :reorder, :map => '/queue/reorder', :provides => [:html, :json] do
    ids = params[:queue] || []
    @queue_items.where(:id => ids).each_with_index do |item, idx|
      item.position = idx
      item.save!
    end
    send_to_sockets("queue_update", "player", "reorder", :queue => params[:queue])
    case content_type
      when :json then render :json, {:result => true}
      when :html then redirect(:queue, :index)
    end
  end

  post :update, :map => '/queue/:id', :provides => [:json, :html] do
    @queue_item = QueueItem.find(params[:id])
    @queue_item.play_state = params[:state] # Enum validates
    result = @queue_item.save!

    send_to_sockets("admin_update", "admin", "state_update", :queue_id => params[:queue_id], :state => params[:state]) if result

    case content_type
      when :json then render :json, {:result => result}
      when :html then redirect(:queue, :index)
    end
  end

  post :action, :map => '/queue/:id/:action' do
    @queue_item = QueueItem.includes(:song).find(params[:id])
    case params[:action]
    when "now"
      @queue_item.play_now
      trigger_action = 'play'
    when "play_next"
      @queue_item.play_next_now
      trigger_action = "play"
    when "next"
      @queue_item.play_next
    when "last"
      @queue_item.play_last
    when "stop"
      @queue_item.stop
      trigger_action = "stop"
    when "prep"
      @queue_item.queue
    when "pause"
      @queue_item.pause
      trigger_action = "pause"
    when "unpause"
      @queue_item.unpause
      trigger_action = "unpause"
    end

    # Tell the player we moved its cheese.
    send_to_sockets(trigger_action, "player", params[:action], :queue_id => params[:id])

    redirect url(:queue, :index)
  end

end
