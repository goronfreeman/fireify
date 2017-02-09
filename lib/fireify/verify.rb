require 'base64'
require 'json'
require 'jwt'

module Fireify
  class Verify
    private

    def parse_token(token)
      @header = JSON.parse(Base64.urlsafe_decode64(token.split('.')[0]))
      @payload = JSON.parse(Base64.urlsafe_decode64(token.split('.')[1]))
    end
  end
end
