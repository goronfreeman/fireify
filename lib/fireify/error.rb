require 'jwt/error'

module Fireify
  class InvalidAlgorithmError < JWT::VerificationError; end
  class InvalidKeyIdError < JWT::VerificationError; end
  class InvalidSubError < JWT::VerificationError; end
end
