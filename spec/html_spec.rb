# coding: utf-8
require 'spec_helper'

describe StringTools::HTML do
  describe '.remove_external_links' do
    context 'whitelist option empty' do
      subject { StringTools::HTML.remove_links(html, whitelist: []) }

      context 'content without links' do
        let(:html) { ' <b>hello</b> <script>alert("world")</script> ' }

        it 'should return html as is' do
          is_expected.to eq html
        end
      end

      context 'content with links' do
        let(:html) do
          <<-MARKUP
            <a href="https://google.com"><span>goo</span><span>gle</span></a>
            <a href="https://yandex.ru"><span>yan</span><span>dex</span></a>
          MARKUP
        end

        it 'should return markup without links' do
          is_expected.to eq(<<-MARKUP)
            <span>goo</span><span>gle</span>
            <span>yan</span><span>dex</span>
          MARKUP
        end
      end

      context 'content with recursive markup' do
        let(:html) do
          <<-MARKUP
            <a href="https://google.com"><a href="https://google.com">goo</a><span>gle</span></a>
            <a href="https://yandex.ru"><span>yan</span><span>dex</span></a>
          MARKUP
        end

        it 'should return content without links' do
          is_expected.to eq(<<-MARKUP)
            goo<span>gle</span>
            <span>yan</span><span>dex</span>
          MARKUP
        end
      end
    end

    context 'when whitelist passed' do
      subject { StringTools::HTML.remove_links(html, whitelist: ['yandex.ru']) }

      context 'domain link match to whitelisted' do
        let(:html) do
          <<-MARKUP
            <a href="https://google.com"><span>goo</span><span>gle</span></a>
            <a href="https://yandex.ru"><span>yan</span><span>dex</span></a>
          MARKUP
        end

        it 'should keep only whitelisted links' do
          is_expected.to eq(<<-MARKUP)
            <span>goo</span><span>gle</span>
            <a href="https://yandex.ru"><span>yan</span><span>dex</span></a>
          MARKUP
        end
      end

      context 'link domain is subdomain of whitelisted' do
        let(:html) do
          <<-MARKUP
            <a href="https://google.com"><span>goo</span><span>gle</span></a>
            <a href="https://www.yandex.ru"><span>yan</span><span>dex</span></a>
          MARKUP
        end

        it 'should keep only whitelisted links' do
          is_expected.to eq(<<-MARKUP)
            <span>goo</span><span>gle</span>
            <a href="https://www.yandex.ru"><span>yan</span><span>dex</span></a>
          MARKUP
        end
      end

      context 'link domain is parent domain of whitelisted' do
        subject { StringTools::HTML.remove_links(html, whitelist: ['www.yandex.ru']) }

        let(:html) do
          <<-MARKUP
            <a href="https://google.com"><span>goo</span><span>gle</span></a>
            <a href="https://yandex.ru"><span>yan</span><span>dex</span></a>
          MARKUP
        end

        it 'should remove link' do
          is_expected.to eq(<<-MARKUP)
            <span>goo</span><span>gle</span>
            <span>yan</span><span>dex</span>
          MARKUP
        end
      end
    end
  end
end
