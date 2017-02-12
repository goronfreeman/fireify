require 'fireify'

describe Fireify do
  describe '#configure' do
    before do
      Fireify.configure do |config|
        config.project_id = 'fireify'
      end
    end

    it 'sets the project_id to the given value' do
      expect(Fireify.configuration.project_id).to eq('fireify')
    end
  end
end
