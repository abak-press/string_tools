require 'spec_helper'

describe String do
  describe '#mb_downcase' do
    it { expect("Кириллица".mb_downcase).to eq("кириллица") }
  end

  describe '#remove_nonprintable' do
    let(:string) { "\uFDD1string\uFFFE \uFFFFwith\uFDEF weird characters\uFDD0" }

    it { expect(string.remove_nonprintable).to eq 'string with weird characters' }

    context 'when string with \n' do
      let(:string) { "one\ntwo" }

      it { expect(string.remove_nonprintable).to eq string }
    end

    context 'when string with \t' do
      let(:string) { "one\ttwo" }

      it { expect(string.remove_nonprintable).to eq string }
    end
  end

  describe '#remove_nonprintable!' do
    let(:string) { "\uFDD1string\uFFFE \uFFFFwith\uFDEF weird characters\uFDD0" }

    it { expect { string.remove_nonprintable! }.to change { string }.to('string with weird characters') }
  end
end
