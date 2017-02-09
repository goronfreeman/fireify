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
end
