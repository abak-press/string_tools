require 'spec_helper'

RSpec.describe StringTools::HTML::Truncate do
  describe '#call' do
    subject { described_class.new(content, limit: limit).call }

    context 'when content length is in limit' do
      let(:content) { 'abcde' }
      let(:limit) { content.length }

      it { is_expected.to eq content }

      context 'content is a img' do
        let(:content) { '<img src="http://example.com/1.png" />' }
        let(:limit) { content.length }

        it { is_expected.to eq content }
      end

      context 'tag without content' do
        let(:content) { '<p></p>' }
        let(:limit) { content.length }

        it { is_expected.to eq content }
      end
    end

    context 'when simple content length is exceeded limit' do
      let(:content) { '<p>abcde</p>' }
      let(:limit) { 8 }

      it { is_expected.to eq '<p>a</p>' }

      context 'content is a img' do
        let(:content) { '<img src="http://example.com/1.png" />' }
        let(:limit) { content.length - 1 }

        it { is_expected.to eq '' }
      end

      context 'content is a text with img' do
        let(:content) { 'abc<img src="http://example.com/1.png" />' }
        let(:limit) { content.length - 1 }

        it { is_expected.to eq 'abc' }
      end

      context 'content is a img with text' do
        let(:content) { '<img src="http://example.com/1.png" />abc' }
        let(:limit) { content.length - 1 }

        it { is_expected.to eq '<img src="http://example.com/1.png" />ab' }
      end

      context 'when anything can not be deleted' do
        let(:content) { '<p></p>' }
        let(:limit) { 6 }

        it { is_expected.to eq '' }
      end
    end

    context 'when content with sibling nodes length is exceeded limit' do
      let(:content) { '<p>abcde</p><p>12345</p>' }
      let(:limit) { 20 }

      it { is_expected.to eq '<p>abcde</p><p>1</p>' }

      context 'when last node should be deleted' do
        let(:content) { '<p>abcde</p><p>12345</p>' }
        let(:limit) { 8 }

        it { is_expected.to eq '<p>a</p>' }
      end
    end

    context 'table rows' do
      let(:content) { '<tr><td>1</td><td>2</td></tr><tr><td>3</td><td>4</td></tr>' }
      let(:expected) { '<tr><td></td><td></td></tr><tr><td></td><td></td></tr>' }
      let(:limit) { expected.length }

      it { is_expected.to eq expected }
    end
  end
end
