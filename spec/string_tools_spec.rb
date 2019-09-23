# coding: utf-8

require 'spec_helper'

describe StringTools do
  describe '#sanitize' do
    it 'removes style tags from string' do
      sanitized_string = described_class.sanitize('test string<style>body { color: red; }</style>')
      expect(sanitized_string).to eq 'test string'
    end

    it 'removes javascript from string' do
      sanitized_string = described_class.sanitize('test string<script>alert("ALERT");</script>')
      expect(sanitized_string).to eq 'test string'
    end

    it 'does not cut css properties in html' do
      origin_str = '<table><tr><td style="text-align: center;"></td></tr></table>'
      sanitized_string = described_class.sanitize(origin_str)
      expect(sanitized_string).to eq origin_str
    end

    it 'normalize unicode urls in img src attribute' do
      origin_str = '<img src="http://www.фермаежей.рф/images/foo.png">'
      sanitized_string = described_class.sanitize(origin_str)
      expect(sanitized_string).to eq '<img src="http://www.xn--80ajbaetq5a8a.xn--p1ai/images/foo.png">'
    end

    it 'normalize unicode urls in a href attribute' do
      origin_str = '<a href="http://www.фермаежей.рф/">www.фермаежей.рф</a>'
      sanitized_string = described_class.sanitize(origin_str)
      expect(sanitized_string).to eq '<a href="http://www.xn--80ajbaetq5a8a.xn--p1ai/">www.фермаежей.рф</a>'
    end

    it 'should delete links with invalid href but keep content' do
      origin_str = '<a href="http://"><span>a</span>www.фермаежей.рф<span>z</span></a>'
      sanitized_string = described_class.sanitize(origin_str)
      expect(sanitized_string).to eq '<span>a</span>www.фермаежей.рф<span>z</span>'
    end

    it 'should delete images with invalid src' do
      origin_str = '<span>a</span><img src="http://"/><span>z</span>'
      sanitized_string = described_class.sanitize(origin_str)
      expect(sanitized_string).to eq '<span>a</span><span>z</span>'
    end

    it 'removes iframes but keeps youtube' do
      origin_str =
        '<iframe width="20" height="10" src="https://www.dunno.com/embed/qwe" frameborder="0" allowfullscreen>' \
        '</iframe>' \
        '<iframe width="123" height="456" src="https://www.youtube.com/embed/abc" frameborder="0" allowfullscreen>' \
        '</iframe>'
      sanitized_string = described_class.sanitize(origin_str, 'iframe' => %w(src width height frameborder))
      expect(sanitized_string).
        to eq('<iframe width="123" height="456" src="https://www.youtube.com/embed/abc" frameborder="0"></iframe>')
    end

    context 'multiple invocations of the method' do
      it 'does not mess up default config' do
        origin_str = '<p style="text-align: center;" title="foobar"></p>'

        with_custom_config = described_class.sanitize(origin_str, 'p' => %w(style title))
        with_default_config = described_class.sanitize(origin_str)

        expect(with_custom_config).to eq('<p style="text-align: center;" title="foobar"></p>')
        expect(with_default_config).to eq('<p style="text-align: center;"></p>')
      end
    end

    context 'when string contains "s" tag' do
      origin_string = '<s>text</s>'

      it { expect(described_class.sanitize(origin_string)).to eq origin_string }
    end
  end

  describe '#clear_unicode_separator_characters' do
    subject(:clear_unicode_separator_characters) { described_class.clear_unicode_separator_characters(string) }

    context 'string with \u2029\u2029 symbols' do
      let(:string) { File.open('spec/fixtures/separator_characters.txt', &:readline) }

      it { expect(clear_unicode_separator_characters).to eq('indissolublestring') }
    end
  end

  describe '#strip_all_tags_and_entities' do
    subject(:strip_all_tags_and_entities) { described_class.strip_all_tags_and_entities(string) }

    context 'string with html tags' do
      let(:string) { '<a>foo</a><div>bar</div>' }

      it { expect(strip_all_tags_and_entities).to eq('foo bar ') }
    end

    context 'string with whitespaces and tabs' do
      let(:string) { "foo&#9;bar\t  foo" }

      it { expect(strip_all_tags_and_entities).to eq('foobarfoo') }
    end
  end

  describe '#strip_tags_leave_br' do
    subject(:strip_tags_leave_br) { described_class.strip_tags_leave_br(string) }

    context 'string with html list' do
      let(:string) { '<ul><li>foo</li></ul>' }

      it { expect(strip_tags_leave_br).to eq('<br />foo<br /><br />') }
    end

    context 'string with html paragraph' do
      let(:string) { '<p>bar</p>' }

      it { expect(strip_tags_leave_br).to eq('bar<br />') }
    end
  end

  describe '#add_params_to_url' do
    subject(:add_params_to_url) { described_class.add_params_to_url(url, params) }
    let(:url) { 'http://test.com' }
    let(:uri) { 'http://test.com/?param=test' }

    context 'when url with params' do
      let(:params) { {'param' => 'test'} }

      it { expect(add_params_to_url).to eq uri }
    end

    context 'when optional params not passed' do
      it { expect(described_class.add_params_to_url(url)).to eq 'http://test.com/' }
    end

    context 'when url not normalized' do
      let(:url) { 'http://TesT.com:80' }
      let(:params) { {'param' => 'test'} }

      it { expect(add_params_to_url).to eq uri }
    end

    context 'when url without scheme' do
      let(:url) { 'test.com' }
      let(:params) { {'param' => 'test'} }

      it { expect(add_params_to_url).to eq uri }
    end

    context 'when url scheme is https' do
      let(:url) { 'https://test.com' }
      let(:params) { {'param' => 'test'} }

      it { expect(add_params_to_url).to eq 'https://test.com/?param=test' }
    end

    context 'when key is a symbol with same value' do
      let(:url) { 'http://test.com/?a=b' }

      it { expect(described_class.add_params_to_url(url, a: 'c')).to eq 'http://test.com/?a=c' }
    end

    context 'when empty url' do
      let(:url) { '' }

      it 'return nil' do
        expect(described_class.add_params_to_url(url, a: 'b')).to be_nil
      end
    end
  end

  describe '#valid_utf8?' do
    it  { expect(StringTools.valid_utf8?('foobar')).to be true }
    it  { expect(StringTools.valid_utf8?(nil)).to be false }
  end

  describe '#transliteration_variations' do
    describe 'maps consitency' do
      it do
        expect(described_class::Transliteration::LAYOUT_EN_TO_RU_MAP.size).
          to eq ::StringTools::Transliteration::LAYOUT_RU_TO_EN_MAP.keys.size
      end
      it do
        expect(::StringTools::Transliteration::LAYOUT_EN_TO_RU_MAP.keys).
          to match_array ::StringTools::Transliteration::LAYOUT_RU_TO_EN_MAP.values
      end
      it do
        expect(::StringTools::Transliteration::LAYOUT_RU_TO_EN_MAP.keys).
          to match_array ::StringTools::Transliteration::LAYOUT_EN_TO_RU_MAP.values
      end
    end

    let(:subject) { described_class.transliteration_variations(str) }
    context 'when english string' do
      let(:str) { 'qwertyuiop[]asdfghjkl;\'zxcvbnm,./' }

      it do
        expect(subject).to match_array [str,
                                        'йцукенгшщзхъфывапролджэячсмитьбю.',
                                        'jczukengshshhzx``fy`vaproldzhe`yachsmit`byu.']
      end
    end

    context 'when russian string' do
      let(:str) { 'йцукенгшщзхъфывапролджэячсмитьбю.' }

      it do
        expect(subject).to match_array [str,
                                        'qwertyuiop[]asdfghjkl;\'zxcvbnm,./',
                                        'jczukengshshhzx``fy`vaproldzhe`yachsmit`byu.']
      end
    end

    context 'when string has russian AND english chars' do
      let(:str) { 'abc абв' }

      it { expect(subject).to match_array [str] }
    end

    context 'when string has other language chars' do
      let(:str) { 'ﻮﻴﻜﻴﺒﻳﺪﻳ' }

      it { expect(subject).to match_array [str] }
    end

    context 'when upper case' do
      let(:str) { 'AbCd' }

      it 'preserve case' do
        expect(subject).to match_array [str, 'ФиСв', 'FiSv']
      end
    end
    context 'when string has other chars' do
      let(:str) { '0123456789!*() -_=+ abc' }
      it 'preserves them' do
        expect(subject).to match_array [str,
                                        '0123456789!*() -_=+ фис',
                                        '0123456789!*() -_=+ fis']
      end
    end
  end
end
