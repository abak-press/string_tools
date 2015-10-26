# coding: utf-8

require 'spec_helper'

describe StringTools do
  describe '#sanitize' do
    it 'removes style tags from string' do
      sanitized_string = described_class.sanitize('test string<style>body { color: red; }</style>')
      expect(sanitized_string).to eq 'test string'
    end

    it 'removes javascript from string' do
      sanitized_string = described_class.sanitize('test string<javascript>alert("ALERT");</javascript>' )
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
  end
end
