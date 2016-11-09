# coding: utf-8

require 'spec_helper'

describe String do
  describe '#mb_downcase' do
    it { expect("Кириллица".mb_downcase).to eq("кириллица") }
  end
end
