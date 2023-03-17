FactoryBot.define do
  factory :access_token do
    token { Faker::Crypto.sha256 }
    owner { Faker::Name.first_name.underscore }
    deactivated_at { nil }
    last_accessed_at { nil }
  end
end
