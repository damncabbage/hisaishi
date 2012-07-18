class QueueItem < ActiveRecord::Base
  # Associations
  belongs_to :song

  # Attributes
  enum_attr :play_state, %w(queued ready playing paused stopped finished)
  CURRENT_SONG_STATES = [:ready, :playing, :paused, :stopped]

  # Scopes
  scope :ordered, order('position ASC')
  scope :current_items, where(:play_state => CURRENT_SONG_STATES)

  # Class Methods
  class << self
    def clean_up_positions
      ordered.all.inject(0) do |position,item|
        item.position = position
        item.save!
        position + 1
      end
    end

    def clean_up_queue_states(current_playing_id)
      current = find(current_playing_id)
      where('position < ?', current.position).update_all(:play_state => :finished)
      where('position > ?', current.position).update_all(:play_state => :queued)
      clean_up_positions
    end
  end

  # Instance Methods
  def stop
    update(:play_state => :stopped)
    self.class.clean_up_queue_states(id)
  end

  def queue
    update(:play_state => :queued)
    self.class.clean_up_queue_states(id)
  end

  def pause
    update(:play_state => :paused)
    self.class.clean_up_queue_states(id)
  end

  def unpause
    update(:play_state => :unpaused)
    self.class.clean_up_queue_states(id)
  end

  def play_now
    update(:play_state => :ready)
    # Clear out everything before and after this song:
    self.class.clean_up_queue_states(id)
  end

  # Move this song just after the currently-playing song
  def play_next
    current_position = current_items.ordered.last.try(:position) || -1
    self.class.where('position > ?', current_position).each do |item|
      item.position += 1
      item.save
    end
    self.position = current_position + 1
    self.class.clean_up_positions
  end

  def play_last
    update(
      :play_state => :queued,
      :position => (ordered.last.try(:position) || -1) + 1
    )
    self.class.clean_up_positions
  end

  def play_next_now
    self.class.ordered.where(:position > position).first.try(:play_now)
  end

end
