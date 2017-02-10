require 'fireify'

CERT_PATH = File.join(File.dirname(__FILE__), 'fixtures', 'certs')

describe Fireify::Verify do
  let(:fireify) { Fireify::Verify.new }
  let(:token) { 'eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJleHAiOjg2NTQ4NjU0NjI2MiwidiI6MCwiZCI6eyJ1aWQiOiJrYXRvIn0sImlhdCI6MTQ4NjYzMjY2Mn0.Q91UVaOcZY2Ci2qiyqqwhx2XIyaR_oPCqMnEujnGnVA' }

  describe '#parse_token' do
    before do
      fireify.send(:parse_token, token)
    end

    it 'assigns @header' do
      expect(fireify.instance_variable_get(:@header)).to_not be_nil
    end

    it 'assigns @payload' do
      expect(fireify.instance_variable_get(:@payload)).to_not be_nil
    end
  end

  describe '#retrieve_certificates' do
    before do
      fireify.send(:retrieve_certificates)
    end

    it 'assigns @valid_certificates' do
      expect(fireify.instance_variable_get(:@valid_certificates))
        .to_not be_nil
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
    let(:header) { { 'alg' => 'RS256', 'kid' => '00c635a74a0d749cbb7177dc4bb917929814be5c' } }
    let(:valid_certificates) { JSON.parse(File.read(File.join(CERT_PATH, 'rs256.json'))) }

    before do
      fireify.instance_variable_set(:@header, header)
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
    let(:header) { { 'alg' => 'RS256' } }
    let(:valid_alg) { 'RS256' }
    let(:invalid_alg) { 'HS256' }

    before do
      fireify.instance_variable_set(:@header, header)
    end

    it 'returns if the hash algorithm equals "RS256"' do
      expect(fireify.send(:verify_alg, valid_alg))
        .to be_nil
    end

    it 'raises Fireify::InvalidAlgorithmError if the hash algorithm does not equal "RS256"' do
      expect { fireify.send(:verify_alg, invalid_alg) }
        .to raise_error(Fireify::InvalidAlgorithmError)
    end
  end

  describe '#verify_kid' do
    let(:header) { { 'alg' => 'RS256', 'kid' => '00c635a74a0d749cbb7177dc4bb917929814be5c' } }
    let(:valid_certificates) { JSON.parse(File.read(File.join(CERT_PATH, 'rs256.json'))) }
    let(:valid_kid) { '00c635a74a0d749cbb7177dc4bb917929814be5c' }
    let(:invalid_kid) { 'notavalidkid' }

    before do
      fireify.instance_variable_set(:@header, header)
    end

    it 'returns if the kid claim is the key to a valid certificate' do
      expect(fireify.send(:verify_kid, valid_kid, valid_certificates))
        .to be_nil
    end

    it 'raises Fireify::InvalidAlgorithmError if the hash algorithm does not equal "RS256"' do
      expect { fireify.send(:verify_kid, invalid_kid, valid_certificates) }
        .to raise_error(Fireify::InvalidKeyIdError)
    end
  end

  describe '#verify_payload' do
    describe 'expiration time' do
      it 'returns if exp is in the future' do
        payload = { 'exp' => 865486546262 }
        fireify.instance_variable_set(:@payload, payload)

        expect(fireify.send(:verify_payload)).to be_nil
      end

      it 'raises JWT::ExpiredSignature if exp is in the past' do
        payload = { 'exp' => 1486631562 }
        fireify.instance_variable_set(:@payload, payload)

        expect { fireify.send(:verify_payload) }
          .to raise_error(JWT::ExpiredSignature)
      end
    end

    describe 'issued-at time' do
      it 'returns if iat is in the past' do
        payload = { 'iat' => 1486627962 }
        fireify.instance_variable_set(:@payload, payload)

        expect(fireify.send(:verify_payload)).to be_nil
      end

      it 'raises JWT::InvalidIatError if iat is in the future' do
        payload = { 'iat' => 865486546262 }
        fireify.instance_variable_set(:@payload, payload)

        expect { fireify.send(:verify_payload) }
          .to raise_error(JWT::InvalidIatError)
      end
    end

    describe 'audience' do
      before do
        fireify.instance_variable_set(:@project_id, 'fireify')
      end

      it 'returns if aud matches Firebase project ID' do
        payload = { 'aud' => 'fireify' }
        fireify.instance_variable_set(:@payload, payload)

        expect(fireify.send(:verify_payload)).to be_nil
      end

      it 'raises JWT::InvalidAudError if aud does not match Firebase project ID' do
        payload = { 'aud' => 'other' }
        fireify.instance_variable_set(:@payload, payload)

        expect { fireify.send(:verify_payload) }
          .to raise_error(JWT::InvalidAudError)
      end
    end
  end
end
