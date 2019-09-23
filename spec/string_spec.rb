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

  describe '#strip_tags' do
    {
      'some<dev>text</dev>' => 'sometext',
      'some<a href="link">text</a>' => 'sometext',
      '1 & 2 + 3 < 5 > 6' => '1 & 2 + 3 < 5 > 6',
      '<<li>text</li>' => '<text',
      'some<!-- comment -->text' => 'sometext',
      'some<ul>text' => 'sometext',
      'some<script>text</script>' => 'sometext',
      'some<!-- comment' => 'some<-- comment',
      '<h1 style="coller:red">>text</h1>>' => '>text>',
      " <ul>list<li>text</li>\n  <li>text2</li> " => " listtext\n  text2 "
    }.each do |example_string, result|
      context "when string '#{example_string}'" do
        it { expect(example_string.dup.strip_tags).to eq result }
      end
    end
  end
end
