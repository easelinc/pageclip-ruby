require 'spec_helper'

describe 'Pageclip' do
  subject do
    Pageclip
  end

  let(:api_key) { 'key' }
  let(:url) { 'http://www.example.com' }
  let(:secret) { 'a' }

  describe 'configuring' do
    it 'can set the api key' do
      subject.configuration.reset!
      subject.configure do |config|
        config.api_key = api_key
        config.job_defaults = {}
      end
      subject.configuration.api_key.should eq(api_key)
    end
  end

  describe 'taking a screenshot' do
    context 'with configuration' do
      before do
        subject.configuration.reset!
        subject.configure do |config|
          config.api_key = api_key
        end
      end

      it 'can request with just a url' do
        stub = stub_request(:get, 'http://api.pageclip.io/v1/screenshots/').
          with(:query => {'url' => url, 'api_key' => api_key})
        subject.screenshot(url)
        stub.should have_been_requested
      end

      it 'can request with a url and options' do
        stub = stub_request(:get, 'http://api.pageclip.io/v1/screenshots/').
          with(:query => {'url' => url, 'api_key' => api_key, 'secret' => secret})
        subject.screenshot(url, :secret => secret)
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
      it 'handles rate limit errors' do
        stub = stub_request(:get, 'http://api.pageclip.io/v1/screenshots/').
          with(:query => {'url' => url, 'api_key' => api_key}).to_return(:status => 429)
        expect { subject.screenshot(url) }.to raise_error(Pageclip::RateLimitedError)
      end
    end
    context 'with default job options' do
      before do
        subject.configuration.reset!
        subject.configure do |config|
          config.api_key = api_key
          config.job_defaults = {
            :secret => secret
          }
        end
      end

      it 'can request with just a url' do
        stub = stub_request(:get, 'http://api.pageclip.io/v1/screenshots/').
          with(:query => {'url' => url, 'api_key' => api_key, 'secret' => secret})
        subject.screenshot(url)
        stub.should have_been_requested
      end

      it 'can override a property' do
        stub = stub_request(:get, 'http://api.pageclip.io/v1/screenshots/').
          with(:query => {'url' => url, 'api_key' => api_key, 'secret' => 'b'})
        subject.screenshot(url, :secret => 'b')
        stub.should have_been_requested
      end
    end
    context 'with a logger' do
      before do
        subject.configuration.reset!
        subject.configure do |config|
          config.api_key = api_key
          config.logger = logger
        end
      end

      let(:logger) {
        class MyLogger
          attr_reader :messages

          def initialize
            @messages = []
          end

          def info(message)
            @messages << message
          end
        end
        MyLogger.new
      }

      it 'captures a message on success' do
        stub = stub_request(:get, 'http://api.pageclip.io/v1/screenshots/').
          with(:query => {'url' => url, 'api_key' => api_key, 'secret' => 'b'})
        subject.screenshot(url, :secret => 'b')
        stub.should have_been_requested
        logger.messages.length.should eq(1)
        logger.messages[0].should match(/\[Pageclip 200 [0-9\.]+s\] Requested #{url}/)
      end

      it 'captures a message on failed response' do
        stub = stub_request(:get, 'http://api.pageclip.io/v1/screenshots/').
          with(:query => {'url' => url, 'api_key' => api_key, 'secret' => 'b'}).to_return(:status => 403)
        expect { subject.screenshot(url, :secret => 'b') }.to raise_error(Pageclip::UnauthorizedError)
        stub.should have_been_requested
        logger.messages.length.should eq(1)
        logger.messages[0].should match(/\[Pageclip 403 [0-9\.]+s\] Requested #{url}/)
      end

      it 'captures a message on exception' do
        stub = stub_request(:get, 'http://api.pageclip.io/v1/screenshots/').
          with(:query => {'url' => url, 'api_key' => api_key, 'secret' => 'b'}).to_raise(Timeout::Error)
        expect { subject.screenshot(url, :secret => 'b') }.to raise_error(Pageclip::TimeoutError)
        stub.should have_been_requested
        logger.messages.length.should eq(1)
        logger.messages[0].should match(/\[Pageclip - \?+s\] Requested #{url}/)
      end
    end
  end
end
