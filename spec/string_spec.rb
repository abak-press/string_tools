# coding: utf-8

require 'spec_helper'

describe String do
  describe '#mb_downcase' do
    it { expect("Кириллица".mb_downcase).to eq("кириллица") }
  end

  describe '#remove_nonprintable' do
    let(:string) { "\uFDD1string\uFFFE \uFFFFwith\uFDEF weird characters\uFDD0" }

    it { expect(string.remove_nonprintable).to eq 'string with weird characters' }
  end

  describe '#remove_nonprintable!' do
    let(:string) { "\uFDD1string\uFFFE \uFFFFwith\uFDEF weird characters\uFDD0" }

    it { expect { string.remove_nonprintable! }.to change { string }.to('string with weird characters') }
  end
end
