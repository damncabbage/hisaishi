FactoryGirl.define do

  factory :song do
    title { Faker::HipsterIpsum.words(rand(2)+2) }
    artist { Faker::HipsterIpsum.words(rand(2)+2) }
    album { Faker::HipsterIpsum.words(rand(2)+2) }
    origin_title "TODO"
    origin_type "TODO"
    origin_medium "TODO"
    genre { %w(Country Western J-Pop).sample }
    language { %w(en ja).sample }
    karaoke { [:true, :false, :unknown].sample }
    source_dir "TODO"
    audio_file "TODO"
    lyrics_file "TODO"
    image_file "TODO"
    length { rand(900) + 200 }
    yes 0
    no 0
    unknown 0
  end

end
