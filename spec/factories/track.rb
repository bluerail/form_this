FactoryGirl.define do
  factory :track do
    name { Faker::Hacker.say_something_smart }
    trackno { Faker::Number.digit }
    album
  end
end
