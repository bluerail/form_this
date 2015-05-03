FactoryGirl.define do
  factory :album do
    name { Faker::Hacker.verb }
    release_date { Faker::Date.between 100.years.ago, Date.today }
    release_type :album
    artist
    genre
  end
end
