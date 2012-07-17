require File.expand_path('../spec_helper.rb', File.dirname(__FILE__))

# See for further examples: https://github.com/rails3book/ticketee/blob/master/spec/api/v3/json/tickets_spec.rb

describe "Hisaishi Queue", :type => :api do
  # An example song for us to add.
  let!(:song) { FactoryGirl.create(:song) }

  context "when queuing a song" do
    before(:each) do
      pin_login!
      post '/queue-submit', :song_id => song.id, :requester => "Frank"
    end

    it "should be in the queue" do
      get '/queue.jsonp'
      response = JSON.parse last_response.body
      queue = response["queue"]

      queue.length.should == 1
      queue.first["id"].should == song.id.to_i
      queue.first["requester"].should == "Frank"
    end
  end

  # TODO: Move this helper out to spec/support/api_helper.rb or similar.
  def pin_login!(pin="1234")
    post '/unlock-screen', :pin => pin
  end
end
