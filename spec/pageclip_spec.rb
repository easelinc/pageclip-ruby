require 'spec_helper'

describe 'Pageclip' do
  subject do
    Pageclip
  end
  describe 'configuring' do
    it 'can set the api key' do
      subject.configure do |config|
        config.api_key = 'key'
      end
      subject.configuration.api_key.should eq('key')
    end
  end
  describe 'taking a screenshot' do
    context 'with configuration' do
      before do
        subject.configure do |config|
          config.api_key = api_key
        end
      end

      let(:url) { 'http://www.example.com' }
      let(:api_key) { 'key' }

      it 'can request with just a url' do
        stub = stub_request(:get, 'http://api.pageclip.io/v1/screenshots/').
          with(:query => {'url' => url, 'api_key' => api_key})
        subject.screenshot(url)
        stub.should have_been_requested
      end
      it 'can request with a url and options' do
        stub = stub_request(:get, 'http://api.pageclip.io/v1/screenshots/').
          with(:query => {'url' => url, 'api_key' => api_key, 'secret' => 'a'})
        subject.screenshot(url, :secret => 'a')
        stub.should have_been_requested
      end
      it 'handles timeouts'
      it 'handles unauthorized errors'
      it 'handles rate limit errors'
    end
    context 'with default job options' do
      it 'can request with just a url'
      it 'can override a property'
    end
    context 'with a logger' do
      it 'can request with just a url'
    end
  end
end
