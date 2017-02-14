require 'fireify'
require 'fireify/configuration'
require 'fireify/error'
require 'json'
require 'jwt'
require 'net/http'

module Fireify
  class Verify
    attr_reader :account_details

    def verify_token(token)
      parse_token(token)
      retrieve_certificates
      verify_header
      verify_payload
      verify_signature(token)

      @account_details = @payload
    end

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
      uri = "https://securetoken.google.com/#{Fireify.configuration.project_id}"
      options = { aud: Fireify.configuration.project_id, iss: uri, verify_iat: true, verify_aud: true, verify_iss: true, verify_sub: true, leeway: 0 }
      jwt = JWT::Verify.new(@payload, options)

      jwt.verify_expiration
      jwt.verify_iat
      jwt.verify_aud
      jwt.verify_iss
      verify_sub(@payload['sub'])
    end

    def verify_sub(sub)
      return unless sub.nil? || sub.empty?
      raise(Fireify::InvalidSubError, "Invalid subject. Expected a non-empty string, received #{sub} || <none>")
    end

    def verify_signature(token)
      cert = OpenSSL::X509::Certificate.new(@valid_certificates[@header['kid']])
      public_key = cert.public_key

      JWT.decode(token, public_key, true, algorithm: 'RS256')
    end
  end
end
