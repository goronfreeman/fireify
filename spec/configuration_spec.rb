require 'fireify'

describe Fireify::Configuration do
  describe '#project_id=' do
    it 'can set the value' do
      config = Fireify::Configuration.new
      config.project_id = 'fireify'

      expect(config.project_id).to eq('fireify')
    end
  end
end
