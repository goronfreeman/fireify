require 'base64'
require 'json'
require 'jwt'
require 'net/http'

module Fireify
  class Verify
    private

    def parse_token(token)
      @header = JSON.parse(Base64.urlsafe_decode64(token.split('.')[0]))
      @payload = JSON.parse(Base64.urlsafe_decode64(token.split('.')[1]))
    end

    def retrieve_certificates
      uri = URI('https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com')
      @valid_certificates = JSON.parse(Net::HTTP.get(uri))
    end

    def verify_header
      verify_alg(@header['alg'])
      verify_kid(@header['kid'], @valid_certificates)
    end

    def verify_alg(alg)
      return if alg == 'RS256'
      raise(Fireify::InvalidAlgorithmError, "Invalid algorithm. Expected RS256, received #{@header['alg'] || '<none>'}")
    end

    def verify_kid(kid, certs)
      return if certs.keys.include?(kid)
      raise(Fireify::InvalidKeyIdError, "Invalid key ID. Expected one of the public keys listed at https://www.googleapis.com/robot/v1/metadata/x509/securetoken@system.gserviceaccount.com, received #{@header['kid'] || '<none>'}")
    end

    def verify_payload
      options = { verify_iat: true, verify_aud: true, verify_iss: true, verify_sub: true, leeway: 0 }
      jwt = JWT::Verify.new(@payload, options)

      jwt.verify_expiration
      jwt.verify_iat
    end
  end
end
