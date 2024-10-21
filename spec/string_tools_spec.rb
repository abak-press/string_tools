# coding: utf-8
# frozen_string_literal: true

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

    it 'check youtube shorts' do
      origin_str =
        '<iframe width="123" height="456" ' \
        'src="https://youtu.be/sCS0Z13KYmI?si=xHFqyMAv2f0rXEe0" frameborder="0" allowfullscreen>' \
        '</iframe>'
      sanitized_string = described_class.sanitize(origin_str, 'iframe' => %w[src width height frameborder])
      expect(sanitized_string).to eq(
        '<iframe width="123" height="456" ' \
        'src="https://youtu.be/sCS0Z13KYmI?si=xHFqyMAv2f0rXEe0" frameborder="0"></iframe>'
      )
    end

    it 'check youtube iframe 1' do
      origin_str =
        '<iframe width="560" height="315" ' \
        'src="https://www.youtube.com/embed/q2hv02hi40U?si=-Hw9dc3lT5rMhGZh&amp;controls=0" ' \
        'title="YouTube video player" frameborder="0" ' \
        'allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; ' \
        'web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>'
      sanitized_string = described_class.sanitize(
        origin_str,
        'iframe' => %w[
          src
          width
          height
          frameborder
          title
          allow
          referrerpolicy
          allowfullscreen
        ]
      )
      expect(sanitized_string).to eq(
        '<iframe width="560" height="315" ' \
        'src="https://www.youtube.com/embed/q2hv02hi40U?si=-Hw9dc3lT5rMhGZh&amp;controls=0" ' \
        'title="YouTube video player" frameborder="0" ' \
        'allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" ' \
        'referrerpolicy="strict-origin-when-cross-origin" allowfullscreen=""></iframe>'
      )
    end

    it 'check youtube iframe 2' do
      origin_str =
        '<iframe width="560" height="315"' \
        'src="https://www.youtube.com/embed/q2hv02hi40U?si=-Hw9dc3lT5rMhGZh&amp;controls=0&amp;start=6"' \
        'title="YouTube video player" frameborder="0"' \
        'allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"' \
        'referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>'
      sanitized_string = described_class.sanitize(
        origin_str,
        'iframe' => %w[
          src
          width
          height
          frameborder
          title
          allow
          referrerpolicy
          allowfullscreen
        ]
      )
      expect(sanitized_string).to eq(
        '<iframe width="560" height="315" ' \
        'src="https://www.youtube.com/embed/q2hv02hi40U?si=-Hw9dc3lT5rMhGZh&amp;controls=0&amp;start=6" ' \
        'title="YouTube video player" frameborder="0" ' \
        'allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" ' \
        'referrerpolicy="strict-origin-when-cross-origin" allowfullscreen=""></iframe>'
      )
    end

    it 'check youtube iframe 3' do
      origin_str =
        '<iframe width="560" height="315"' \
        'src="https://www.youtube.com/embed/q2hv02hi40U?si=-Hw9dc3lT5rMhGZh&amp;controls=0"' \
        'title="YouTube video player" frameborder="0"' \
        'allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"' \
        'referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>'
      sanitized_string = described_class.sanitize(
        origin_str,
        'iframe' => %w[
          src
          width
          height
          frameborder
          title
          allow
          referrerpolicy
          allowfullscreen
        ]
      )
      expect(sanitized_string).
        to eq(
          '<iframe width="560" height="315" ' \
          'src="https://www.youtube.com/embed/q2hv02hi40U?si=-Hw9dc3lT5rMhGZh&amp;controls=0" ' \
          'title="YouTube video player" frameborder="0" ' \
          'allow="accelerometer; autoplay; clipboard-write; ' \
          'encrypted-media; gyroscope; picture-in-picture; web-share" ' \
          'referrerpolicy="strict-origin-when-cross-origin" allowfullscreen=""></iframe>'
        )
    end

    it 'check youtube iframe 3 for wrong values' do
      origin_str =
        '<iframe width="560" height="315"' \
        'src="https://www.yuotube.com/embed/q2hv02hi40U?si=-Hw9dc3lT5rMhGZh&amp;controls=0"' \
        'title="YouTube video player" frameborder="0"' \
        'allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"' \
        'referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>'
      sanitized_string = described_class.sanitize(
        origin_str,
        'iframe' => %w[
          src
          width
          height
          frameborder
          title
          allow
          referrerpolicy
          allowfullscreen
        ]
      )
      expect(sanitized_string).
        to eq(
          ''
        )
    end

    it 'check youtube iframe 4' do
      origin_str =
        '<iframe width="560" height="315"' \
        'src="https://www.youtube-nocookie.com/embed/q2hv02hi40U?si=-Hw9dc3lT5rMhGZh&amp;controls=0"' \
        'title="YouTube video player" frameborder="0"' \
        'allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"' \
        'referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>'
      sanitized_string = described_class.sanitize(
        origin_str,
        'iframe' => %w[
          src
          width
          height
          frameborder
          title
          allow
          referrerpolicy
          allowfullscreen
        ]
      )
      expect(sanitized_string).to eq(
        '<iframe width="560" height="315" ' \
        'src="https://www.youtube-nocookie.com/embed/q2hv02hi40U?si=-Hw9dc3lT5rMhGZh&amp;controls=0" ' \
        'title="YouTube video player" frameborder="0" ' \
        'allow="accelerometer; autoplay; clipboard-write; ' \
        'encrypted-media; gyroscope; picture-in-picture; web-share" ' \
        'referrerpolicy="strict-origin-when-cross-origin" allowfullscreen=""></iframe>'
      )
    end

    it 'check youtube iframe 4 for wrong values' do
      origin_str =
        '<iframe width="560" height="315"' \
        'src="https//www.youtube-nocookie.com/embed/q2hv02hi40U?si=-Hw9dc3lT5rMhGZh&amp;controls=0"' \
        'src="https://youtube-nocookie.com/bembed/q2hv02hi40U?si=-Hw9dc3lT5rMhGZh&amp;controls=0"' \
        'title="YouTube video player" frameborder="0"' \
        'allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share"' \
        'referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>'
      sanitized_string = described_class.sanitize(
        origin_str,
        'iframe' => %w[
          src
          width
          height
          frameborder
          title
          allow
          referrerpolicy
          allowfullscreen
        ]
      )
      expect(sanitized_string).to_not eq(
        '<iframe width="560" height="315" ' \
        'src="https://www.youtube-nocookie.com/embed/q2hv02hi40U?si=-Hw9dc3lT5rMhGZh&amp;controls=0" ' \
        'title="YouTube video player" frameborder="0" ' \
        'allow="accelerometer; autoplay; clipboard-write; ' \
        'encrypted-media; gyroscope; picture-in-picture; web-share" ' \
        'referrerpolicy="strict-origin-when-cross-origin" allowfullscreen=""></iframe>'
      )
    end

    it 'removes iframes but keeps rutube' do
      origin_str =
        '<iframe width="20" height="10" src="https://www.dunno.com/embed/qwe" frameborder="0" allowfullscreen>' \
        '</iframe>' \
        '<iframe width="720" height="405" src="http://rutube.ru/video/0edee89644a80afda2f2614af3954e48/">' \
        '</iframe>'
      sanitized_string = described_class.sanitize(origin_str, 'iframe' => %w[src width height frameborder])
      expect(sanitized_string).to eq(
        '<iframe width="720" height="405" ' \
        'src="http://rutube.ru/video/0edee89644a80afda2f2614af3954e48/"></iframe>'
      )
    end

    it 'check rutube iframe 1' do
      origin_str =
        '<iframe width="720" height="405" src="http://rutube.ru/play/embed/815fc1aa6cd10353d0a630f6d2510d52/?t=1" ' \
        'frameBorder="0" allow="clipboard-write; autoplay" webkitAllowFullScreen mozallowfullscreen ' \
        'allowFullScreen></iframe>'
      sanitized_string = described_class.sanitize(
        origin_str,
        'iframe' => %w[
          src
          width
          height
          frameborder
          title
          allow
          webkitallowfullscreen
          mozallowfullscreen
          allowfullscreen
        ]
      )
      expect(sanitized_string).
        to eq(
          '<iframe width="720" height="405" src="http://rutube.ru/play/embed/815fc1aa6cd10353d0a630f6d2510d52/?t=1" ' \
          'frameborder="0" allow="clipboard-write; autoplay" webkitallowfullscreen="" ' \
          'mozallowfullscreen="" allowfullscreen=""></iframe>'
        )
    end

    it 'check rutube iframe 2' do
      origin_str =
        '<iframe width="720" height="405"' \
        'src="http://rutube.ru/play/embed/815fc1aa6cd10353d0a630f6d2510d52/?t=1&stopTime=70" ' \
        'frameBorder="0" allow="clipboard-write; autoplay" webkitAllowFullScreen mozallowfullscreen ' \
        'allowFullScreen></iframe>'
      sanitized_string = described_class.sanitize(
        origin_str,
        'iframe' => %w[
          src
          width
          height
          frameborder
          title
          allow
          webkitallowfullscreen
          mozallowfullscreen
          allowfullscreen
        ]
      )
      expect(sanitized_string).to eq('<iframe width="720" height="405" ' \
      'src="http://rutube.ru/play/embed/815fc1aa6cd10353d0a630f6d2510d52/?t=1&amp;stopTime=70" ' \
      'frameborder="0" allow="clipboard-write; autoplay" webkitallowfullscreen="" mozallowfullscreen="" ' \
      'allowfullscreen=""></iframe>')
    end

    it 'check rutube iframe 3' do
      origin_str =
        '<iframe width="720" height="405" ' \
        'src="https://rutube.ru/play/embed/815fc1aa6cd10353d0a630f6d2510d52/?t=1&stopTime=70" ' \
        'frameBorder="0" allow="clipboard-write; autoplay" webkitAllowFullScreen mozallowfullscreen ' \
        'allowFullScreen></iframe>' \
        '<p><a href="https://rutube.ru/video/815fc1aa6cd10353d0a630f6d2510d52/">' \
        'Как узнать свой ip-адрес</a> на <a href="https://rutube.ru/">RUTUBE</a></p>'
      sanitized_string = described_class.sanitize(
        origin_str,
        'iframe' => %w[
          src
          width
          height
          frameborder
          title
          allow
          webkitallowfullscreen
          mozallowfullscreen
          allowfullscreen
        ]
      )
      expect(sanitized_string).to eq(
        '<iframe width="720" height="405" ' \
        'src="https://rutube.ru/play/embed/815fc1aa6cd10353d0a630f6d2510d52/?t=1&amp;stopTime=70" ' \
        'frameborder="0" allow="clipboard-write; autoplay" webkitallowfullscreen="" mozallowfullscreen="" ' \
        'allowfullscreen=""></iframe>' \
        '<p><a href="https://rutube.ru/video/815fc1aa6cd10353d0a630f6d2510d52/">' \
        'Как узнать свой ip-адрес</a> на <a href="https://rutube.ru/">RUTUBE</a></p>'
      )
    end

    it 'check rutube iframe 4' do
      origin_str =
        '<iframe width="720" height="405" ' \
        'src="https://rutube.ru/play/embed/815fc1aa6cd10353d0a630f6d2510d52/?t=1&stopTime=70" ' \
        'frameBorder="0" allow="clipboard-write; autoplay" webkitAllowFullScreen mozallowfullscreen ' \
        'allowFullScreen></iframe>' \
        '<p><a href="https://rutube.ru/video/815fc1aa6cd10353d0a630f6d2510d52/">' \
        'Как узнать свой ip-адрес</a> от <a href="https://rutube.ru/video/person/29699498/">' \
        'Быстро и просто</a> на <a href="https://rutube.ru/">RUTUBE</a></p>'
      sanitized_string = described_class.sanitize(
        origin_str,
        'iframe' => %w[
          src
          width
          height
          frameborder
          title
          allow
          webkitallowfullscreen
          mozallowfullscreen
          allowfullscreen
        ]
      )
      expect(sanitized_string).to eq(
        '<iframe width="720" height="405" ' \
        'src="https://rutube.ru/play/embed/815fc1aa6cd10353d0a630f6d2510d52/?t=1&amp;stopTime=70" ' \
        'frameborder="0" allow="clipboard-write; autoplay" webkitallowfullscreen="" mozallowfullscreen="" ' \
        'allowfullscreen=""></iframe>' \
        '<p><a href="https://rutube.ru/video/815fc1aa6cd10353d0a630f6d2510d52/">' \
        'Как узнать свой ip-адрес</a> от <a href="https://rutube.ru/video/person/29699498/">' \
        'Быстро и просто</a> на <a href="https://rutube.ru/">RUTUBE</a></p>'
      )
    end

    it 'check rutube iframe 4 for wrong value' do
      origin_str =
        '<iframe width="720" height="405" ' \
        'src="httpa://rutube.ru/play/embed/815fc1aa6cd10353d0a630f6d2510d52/?t=1&stopTime=70" ' \
        'frameBorder="0" allow="clipboard-write; autoplay" webkitAllowFullScreen mozallowfullscreen ' \
        'allowFullScreen></iframe>' \
        '<p><a href="httpa://rutube.ru/video/815fc1aa6cd10353d0a630f6d2510d52/">' \
        'Как узнать свой ip-адрес</a> от <a href="https://rutube.ru/video/person/29699498/">' \
        'Быстро и просто</a> на <a href="https://rutube.ru/">RUTUBE</a></p>'
      sanitized_string = described_class.sanitize(
        origin_str,
        'iframe' => %w[
          src
          width
          height
          frameborder
          title
          allow
          webkitallowfullscreen
          mozallowfullscreen
          allowfullscreen
        ]
      )
      expect(sanitized_string).to_not eq(
        '<iframe width="720" height="405" ' \
        'src="https://rutube.ru/play/embed/815fc1aa6cd10353d0a630f6d2510d52/?t=1&amp;stopTime=70" ' \
        'frameborder="0" allow="clipboard-write; autoplay" webkitallowfullscreen="" mozallowfullscreen="" ' \
        'allowfullscreen=""></iframe>' \
        '<p><a href="https://rutube.ru/video/815fc1aa6cd10353d0a630f6d2510d52/">' \
        'Как узнать свой ip-адрес</a> от <a href="https://rutube.ru/video/person/29699498/">' \
        'Быстро и просто</a> на <a href="https://rutube.ru/">RUTUBE</a></p>'
      )
    end

    it 'check wrong case' do
      origin_str =
        '<iframe width="720" height="405" src="https://rutube.ruyoutu" ' \
        'frameBorder="0" allow="clipboard-write; autoplay" webkitAllowFullScreen mozallowfullscreen ' \
        'allowFullScreen></iframe>'
      sanitized_string = described_class.sanitize(
        origin_str,
        'iframe' => %w[
          src
          width
          height
          frameborder
          title
          allow
          webkitallowfullscreen
          mozallowfullscreen
          allowfullscreen
        ]
      )
      expect(sanitized_string).
        to eq('')
    end

    it 'removes outer link from css when protocols given' do
      origin_str = '<div style="background-image: url(http://i54.tinypic.com/4zuxif.jpg)"></div>'
      sanitized_string = described_class.sanitize(origin_str)
      expect(sanitized_string).to eq('<div></div>')
    end

    it 'do not removes outer link from css when protocols given' do
      origin_str = '<div style="background-image: url(http://i54.tinypic.com/4zuxif.jpg)"></div>'
      sanitized_string = described_class.sanitize(origin_str, protocols: %w[http https])
      expect(sanitized_string).to eq('<div style="background-image: url(http://i54.tinypic.com/4zuxif.jpg)"></div>')
    end

    it 'removes style content' do
      origin_str = '<style type="text/css">body{color: red;}</style>'
      sanitized_string = described_class.sanitize(origin_str)
      expect(sanitized_string).to eq('')
    end

    it 'do not removes style content' do
      origin_str = '<style type="text/css">body{color: red;}</style>'
      sanitized_string = described_class.sanitize(origin_str, 'style' => %w(type), remove_contents: Set['script'])
      expect(sanitized_string).to eq('<style type="text/css">body{color: red;}</style>')
    end

    it 'removes links in alt attribute of img tag' do
      origin_str = '<img scr="http://test.test" alt="http://test.test test https://test.test alt">'
      sanitized_string = described_class.sanitize(origin_str, 'img' => %w(scr alt))
      expect(sanitized_string).to eq('<img scr="http://test.test" alt="test alt">')
    end

    it 'removes alt attribute of img tag if empty value' do
      origin_str = '<img scr="http://test.test" alt="http://test.test">'
      sanitized_string = described_class.sanitize(origin_str, 'img' => %w(scr alt))
      expect(sanitized_string).to eq('<img scr="http://test.test">')
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

    context 'turn off normalization' do
      subject(:add_params_to_url) { described_class.add_params_to_url(url, params, normalize: false) }

      let(:url) do
        'https://www.beautysystems.ru/katalog-kosmetologicheskih-apparatov/dlya-korrekcii-figury/' \
        'pressoterapiya/lympha-%e2%80%afpress-%e2%80%afoptimal/?attribute_pa_lympha-press-optimal=apparat'
      end
      let(:params) { {'param' => 'test'} }

      let(:uri) do
        'https://www.beautysystems.ru/katalog-kosmetologicheskih-apparatov/dlya-korrekcii-figury/' \
        'pressoterapiya/lympha-%e2%80%afpress-%e2%80%afoptimal/?attribute_pa_lympha-press-optimal=apparat' \
        '&param=test'
      end

      it { expect(add_params_to_url).to eq uri }
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
