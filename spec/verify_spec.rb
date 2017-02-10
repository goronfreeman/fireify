require 'fireify/verify'
require 'pry-byebug'

CERT_PATH = File.join(File.dirname(__FILE__), 'fixtures', 'certs')

describe Fireify::Verify do
  let(:fireify) { Fireify::Verify.new('fireify') }
  let(:token) { create_custom_token }

  before do
    def create_custom_token
      private_key = OpenSSL::PKey.read(File.read(File.join(CERT_PATH, 'rs256-private.pem')))
      now_seconds = Time.now.to_i
      payload = { aud: fireify.project_id,
                  iss: "https://securetoken.google.com/#{fireify.project_id}",
                  sub: 'mysubject',
                  iat: now_seconds,
                  exp: now_seconds + (60 * 60) }

      JWT.encode(payload, private_key, 'RS256')
    end

    fireify.send(:parse_token, token)
  end

  skip '#verify_token' do
    describe 'method calls' do
      after do
        fireify.send(:verify_token, token)
      end

      it 'calls #parse_token with the appropriate arguments' do
        expect(fireify).to receive(:parse_token)
          .with(token)
      end

      it 'calls #retrieve_certificates' do
        expect(fireify).to receive(:retrieve_certificates)
      end

      it 'calls #verify_header' do
        expect(fireify).to receive(:verify_header)
      end

      it 'calls #verify_payload' do
        expect(fireify).to receive(:payload)
      end

      it 'calls #verify_signature with the appropriate arguments' do
        expect(fireify).to receive(:verify_signature)
          .with(token)
      end
    end

    it 'returns the subject claim if successful' do
      expect { fireify.send(:verify_token, token) }
        .to eq(fireify.instance_variable_get(@payload)['sub'])
    end
  end

  describe '#parse_token' do
    before do
      fireify.send(:parse_token, token)
    end

    it 'assigns @header' do
      expect(fireify.instance_variable_get(:@header))
        .not_to be_nil
    end

    it 'assigns @payload' do
      expect(fireify.instance_variable_get(:@payload))
        .not_to be_nil
    end
  end

  describe '#retrieve_certificates' do
    before do
      fireify.send(:retrieve_certificates)
    end

    it 'assigns @valid_certificates' do
      expect(fireify.instance_variable_get(:@valid_certificates))
        .not_to be_nil
    end

    it 'retrieves the latest certificates from Google' do
      expect(
        fireify.instance_variable_get(:@valid_certificates)
               .values
               .map { |val| val.start_with?('-----BEGIN CERTIFICATE-----') }
               .uniq
      ).to eq([true])
    end
  end

  describe '#verify_header' do
    before do
      fireify.instance_variable_get(:@header)['kid'] = '00c635a74a0d749cbb7177dc4bb917929814be5c'
      certs = JSON.parse(File.read(File.join(CERT_PATH, 'rs256.json')))
      fireify.instance_variable_set(:@valid_certificates, certs)
    end

    after do
      fireify.send(:verify_header)
    end

    it 'calls #verify_alg with the appropriate arguments' do
      expect(fireify).to receive(:verify_alg)
        .with(fireify.instance_variable_get(:@header)['alg'])
    end

    it 'calls #verify_kid with the appropriate arguments' do
      expect(fireify).to receive(:verify_kid)
        .with(
          fireify.instance_variable_get(:@header)['kid'],
          fireify.instance_variable_get(:@valid_certificates)
        )
    end
  end

  describe '#verify_alg' do
    it 'returns if the hash algorithm equals "RS256"' do
      expect { fireify.send(:verify_alg, 'RS256') }
        .not_to raise_error
    end

    it 'raises Fireify::InvalidAlgorithmError if the hash algorithm does not equal "RS256"' do
      expect { fireify.send(:verify_alg, 'HS256') }
        .to raise_error(Fireify::InvalidAlgorithmError)
    end
  end

  describe '#verify_kid' do
    let(:valid_certificates) { JSON.parse(File.read(File.join(CERT_PATH, 'rs256.json'))) }
    let(:valid_kid) { '00c635a74a0d749cbb7177dc4bb917929814be5c' }
    let(:invalid_kid) { 'notavalidkid' }

    before do
      fireify.instance_variable_get(:@header)['kid'] = '00c635a74a0d749cbb7177dc4bb917929814be5c'
    end

    it 'returns if the kid claim is the key to a valid certificate' do
      expect { fireify.send(:verify_kid, valid_kid, valid_certificates) }
        .not_to raise_error
    end

    it 'raises Fireify::InvalidAlgorithmError if the hash algorithm does not equal "RS256"' do
      expect { fireify.send(:verify_kid, invalid_kid, valid_certificates) }
        .to raise_error(Fireify::InvalidKeyIdError)
    end
  end

  describe '#verify_payload' do
    describe 'expiration time' do
      it 'returns if exp is in the future' do
        fireify.instance_variable_get(:@payload)['exp'] = 865486546262

        expect { fireify.send(:verify_payload) }
          .not_to raise_error
      end

      it 'raises JWT::ExpiredSignature if exp is in the past' do
        fireify.instance_variable_get(:@payload)['exp'] = 1486631562

        expect { fireify.send(:verify_payload) }
          .to raise_error(JWT::ExpiredSignature)
      end
    end

    describe 'issued-at time' do
      it 'returns if iat is in the past' do
        fireify.instance_variable_get(:@payload)['iat'] = 1486627962

        expect { fireify.send(:verify_payload) }
          .not_to raise_error
      end

      it 'raises JWT::InvalidIatError if iat is in the future' do
        fireify.instance_variable_get(:@payload)['iat'] = 865486546262

        expect { fireify.send(:verify_payload) }
          .to raise_error(JWT::InvalidIatError)
      end
    end

    describe 'audience' do
      it 'returns if aud matches Firebase project ID' do
        expect { fireify.send(:verify_payload) }
          .not_to raise_error
      end

      it 'raises JWT::InvalidAudError if aud does not match Firebase project ID' do
        fireify.instance_variable_get(:@payload)['aud'] = 'waterify'

        expect { fireify.send(:verify_payload) }
          .to raise_error(JWT::InvalidAudError)
      end
    end

    describe 'issuer' do
      it 'returns if iss matches https://securetoken.google.com/<projectId>' do
        expect { fireify.send(:verify_payload) }
          .not_to raise_error
      end

      it 'raises JWT::InvalidIssuerError if iss does not match https://securetoken.google.com/<projectId>' do
        fireify.instance_variable_get(:@payload)['iss'] = 'https://securetoken.google.com/waterify'

        expect { fireify.send(:verify_payload) }
          .to raise_error(JWT::InvalidIssuerError)
      end
    end

    describe 'subject' do
      after do
        fireify.send(:verify_payload)
      end

      it 'calls #verify_subject with the appropriate arguments' do
        expect(fireify).to receive(:verify_sub)
          .with(fireify.instance_variable_get(:@payload)['sub'])
      end
    end
  end

  describe '#verify_subject' do
    it 'returns if sub is a non-empty string' do
      expect { fireify.send(:verify_sub, fireify.instance_variable_get(:@payload)['sub']) }
        .not_to raise_error
    end

    it 'raises Fireify::InvalidSubError if sub is an empty string' do
      fireify.instance_variable_get(:@payload)['sub'] = ''

      expect { fireify.send(:verify_sub, fireify.instance_variable_get(:@payload)['sub']) }
        .to raise_error(Fireify::InvalidSubError)
    end

    it 'raises Fireify::InvalidSubError if sub is not included' do
      fireify.instance_variable_get(:@payload).tap { |x| x.delete('sub') }

      expect { fireify.send(:verify_sub, fireify.instance_variable_get(:@payload)['sub']) }
        .to raise_error(Fireify::InvalidSubError)
    end
  end

  describe '#verify_signature' do
    before do
      fireify.instance_variable_get(:@header)['kid'] = '00c635a74a0d749cbb7177dc4bb917929814be5c'
      certs = JSON.parse(File.read(File.join(CERT_PATH, 'rs256.json')))
      fireify.instance_variable_set(:@valid_certificates, certs)
    end

    it 'returns an array with the payload and header if signature is valid' do
      expect(fireify.send(:verify_signature, token))
        .to match_array(
          [fireify.instance_variable_get(:@payload),
           fireify.instance_variable_get(:@header).tap { |x| x.delete('kid') }]
        )
    end
  end
end
