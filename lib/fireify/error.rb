require 'jwt/error'

module Fireify
  class InvalidAlgorithmError < JWT::VerificationError; end
end
