require 'spec_helper'

RSpec.describe StringTools::String, '#to_b' do
  ["0", "f", "F", "false", "FALSE", "off", "OFF", "", "2017-01-01"].each do |val|
    it "returns false" do
      expect(described_class.new(val).to_b).to be false
    end
  end

  %w(1 t T true TRUE on ON).each do |val|
    it "returns true" do
      expect(described_class.new(val).to_b).to be true
    end
  end
end
