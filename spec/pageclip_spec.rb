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

      it 'handles timeouts' do
        stub = stub_request(:get, 'http://api.pageclip.io/v1/screenshots/').
          with(:query => {'url' => url, 'api_key' => api_key}).to_raise(Timeout::Error)
        expect { subject.screenshot(url) }.to raise_error(Pageclip::TimeoutError)
      end

      it 'handles unauthorized errors' do
        stub = stub_request(:get, 'http://api.pageclip.io/v1/screenshots/').
          with(:query => {'url' => url, 'api_key' => api_key}).to_return(:status => 403)
        expect { subject.screenshot(url) }.to raise_error(Pageclip::UnauthorizedError)
      end
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
