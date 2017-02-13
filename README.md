# Fireify

[Firebase](https://firebase.google.com/) token verification for Ruby on Rails.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'fireify'
```

And then execute:

    $ bundle

Run Fireify's generator:

    $ rails generate fireify:install

And then edit the initializer created at `config/initializers.fireify.rb` with
your project's Firebase project ID. You should utilize an environment variable
to store your project ID:

```ruby
Fireify.configure do |config|
  # You can find this value in your project's Firebase console.
  config.project_id = Rails.application.secrets.firebase[:project_id]
end
```

## Usage

Utilize Fireify to ensure tokens sent to your application meet the constraints
specified in the Firebase [documentation](https://firebase.google.com/docs/auth/admin/verify-id-tokens#verify_id_tokens_using_a_third-party_jwt_library).

Basic usage of Fireify to create a user account from a token:

```ruby
fireify = Fireify::Verify.new
token = 'my_firebase_token'

fireify.verify_token(token) # Assuming the token passes verificiation.

User.create(
  email: fireify.account_details['email'],
  name: fireify.account_details['name'],
  picture: fireify.account_details['picture']
)
```

`fireify.account_details` returns a hash of user account details that you can
use to populate whatever database fields make sense for your application.

```ruby
{
  "iss" => "https://securetoken.google.com/firebase-project-id",
  "name" => "John Doe",
  "picture" => "link-to-user-photo.jpg",
  "aud" => "firebase-project-id",
  "auth_time" => 1487014530,
  "user_id" => "uuid",
  "sub" => "uuid",
  "iat" => 1487014531,
  "exp" => 1487018131,
  "email" => "john.doe@example.com",
  "email_verified" => true,
  "firebase" => {
    "identities" => {
      "google.com" => ["identifier"],
      "email" => ["john.doe@example.com"]
    },
    "sign_in_provider" => "google.com"}
}
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/goronfreeman/fireify.
