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

    def verify_alg(alg)
      return true if alg == 'RS256'
      raise(Fireify::InvalidAlgorithmError, "Invalid algorithm. Expected RS256, received #{@header['alg'] || '<none>'}")
    end

    def verify_kid(kid, certs)
      return true if certs.keys.include?(kid)
      raise(Fireify::InvalidKeyIdError, "Invalid key ID. Expected one of the public keys listed at https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com, received #{@header['kid'] || '<none>'}")
    end
  end
end
