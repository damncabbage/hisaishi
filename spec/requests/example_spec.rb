require File.expand_path('../spec_helper.rb', File.dirname(__FILE__))

# This is an example of tests you can make against the
# front end (rather then just the API).

describe "Lock Screen", :type => :request do
  let(:correct_pin)   { "1234" }
  let(:incorrect_pin) { "2222" }

  # Dummy model setup
  let!(:song) { FactoryGirl.create(:song) }

  # Dummy example
  it "should let me in with a valid PIN" do
    visit '/lock-screen'

    correct_pin.chars.each do |number|
      click_button number
    end
    click_button 'Submit'

    page.should have_content("Queue")
  end

end
