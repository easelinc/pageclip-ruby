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
        screenshot = stub_request(:get, 'http://api.pageclip.io/v1/screenshots/').
          with(:headers => {'User-Agent' => "Pageclip Ruby #{Pageclip::VERSION}"}).
          with(:query => {'url' => url, 'api_key' => api_key}).
          to_return(:status => 302, :headers => { :location => 'http://api.pageclip.io/v1/screenshots/1' })
        result = stub_request(:get, 'http://api.pageclip.io/v1/screenshots/1').
          with(:headers => {'User-Agent' => "Pageclip Ruby #{Pageclip::VERSION}"}).
          to_return(:status => 301, :headers => { :location => 'https://s3.amazonaws.com/bucket/1.png' })

        image_url = subject.screenshot(url)
        screenshot.should have_been_requested
        result.should have_been_requested
        image_url.should eq('https://s3.amazonaws.com/bucket/1.png')
      end

      it 'can request with a url and options' do
        screenshot = stub_request(:get, 'http://api.pageclip.io/v1/screenshots/').
          with(:query => {'url' => url, 'api_key' => api_key, 'secret' => secret}).
          to_return(:status => 302, :headers => { :location => 'http://api.pageclip.io/v1/screenshots/1' })
        result = stub_request(:get, 'http://api.pageclip.io/v1/screenshots/1').
          to_return(:status => 301, :headers => { :location => 'https://s3.amazonaws.com/bucket/1.png' })

        image_url = subject.screenshot(url, :secret => secret)
        screenshot.should have_been_requested
        screenshot.should have_been_requested
        result.should have_been_requested
        image_url.should eq('https://s3.amazonaws.com/bucket/1.png')
      end

      describe 'errors' do
        describe 'service responses on initial request' do
          def validate_exception_from_status(status, exception)
            screenshot = stub_request(:get, 'http://api.pageclip.io/v1/screenshots/').
              with(:query => {'url' => url, 'api_key' => api_key}).to_return(:status => status)

            expect { subject.screenshot(url) }.to raise_error(exception)
            screenshot.should have_been_requested
          end

          it 'handles unauthorized' do
            validate_exception_from_status(403, Pageclip::UnauthorizedError)
          end

          it 'handles rate limit' do
            validate_exception_from_status(429, Pageclip::RateLimitedError)
          end

          it 'handles service unavailable errors' do
            validate_exception_from_status(503, Pageclip::ServiceUnavailableError)
          end
        end
        describe 'service responses on screenshot endpoint' do
          def validate_exeception_from_status(status, exception)
            screenshot = stub_request(:get, 'http://api.pageclip.io/v1/screenshots/').
              with(:query => {'url' => url, 'api_key' => api_key}).
              to_return(:status => 302, :headers => { :location => 'http://api.pageclip.io/v1/screenshots/1' })
            result = stub_request(:get, 'http://api.pageclip.io/v1/screenshots/1').
              to_return(:status => status)

            expect { subject.screenshot(url) }.to raise_error(exception)
            screenshot.should have_been_requested
          end

          it 'handles service unavailable errors on results' do
            validate_exeception_from_status(503, Pageclip::ServiceUnavailableError)
          end

          it 'handles screenshot errors' do
            validate_exeception_from_status(410, Pageclip::ScreenshotError)
          end
        end

        describe 'network errors on initial request' do
          def validate_exception_from_exception(network_exception, exception)
            screenshot = stub_request(:get, 'http://api.pageclip.io/v1/screenshots/').
              with(:query => {'url' => url, 'api_key' => api_key}).to_raise(network_exception)

            expect { subject.screenshot(url) }.to raise_error(exception)
            screenshot.should have_been_requested
          end

          it 'handles timeouts' do
            validate_exception_from_exception(Timeout::Error, Pageclip::TimeoutError)
          end
        end

        describe 'intermittant network errors on initial request' do
          def validate_success_on_intermittant_exception(network_exception)
            screenshot = stub_request(:get, 'http://api.pageclip.io/v1/screenshots/').
              with(:query => {'url' => url, 'api_key' => api_key}).
              to_raise(network_exception).then.to_return(:status => 302, :headers => { :location => 'http://api.pageclip.io/v1/screenshots/1' })
            result = stub_request(:get, 'http://api.pageclip.io/v1/screenshots/1').
              to_return(:status => 301, :headers => { :location => 'http://s3.amazonaws.com/bucket/1.png' })
            Kernel.should_receive(:sleep).with(1)

            subject.screenshot(url).should eq('http://s3.amazonaws.com/bucket/1.png')
            screenshot.should have_been_requested.times(2)
            result.should have_been_requested
          end

          it 'handles timeouts' do
            validate_success_on_intermittant_exception(Errno::ETIMEDOUT)
          end

          it 'handles end of file errors' do
            validate_success_on_intermittant_exception(EOFError)
          end

          it 'handles connection refused errors' do
            validate_success_on_intermittant_exception(Errno::ECONNREFUSED)
          end
        end

        describe 'prolonged network errors on initial request' do
          def validate_exception_on_prolonged_exception(network_exception, exception)
            screenshot = stub_request(:get, 'http://api.pageclip.io/v1/screenshots/').
              with(:query => {'url' => url, 'api_key' => api_key}).to_raise(network_exception).
              then.to_raise(network_exception).then.to_raise(network_exception)
            Kernel.should_receive(:sleep).with(1)
            Kernel.should_receive(:sleep).with(2)
            Kernel.should_receive(:sleep).with(3)

            expect { subject.screenshot(url) }.to raise_error(exception)
            screenshot.should have_been_requested.times(4)
          end

          it 'handles timeouts' do
            validate_exception_on_prolonged_exception(Errno::ETIMEDOUT, Pageclip::ServiceUnavailableError)
          end

          it 'handles end of file errors' do
            validate_exception_on_prolonged_exception(EOFError, Pageclip::ServiceUnavailableError)
          end

          it 'handles connection refused errors' do
            validate_exception_on_prolonged_exception(Errno::ECONNREFUSED, Pageclip::ServiceUnavailableError)
          end
        end

        describe 'intermittant network errors on the screenshot endpoint' do
          def validate_success_on_intermittant_exception(network_exception)
            screenshot = stub_request(:get, 'http://api.pageclip.io/v1/screenshots/').
              with(:query => {'url' => url, 'api_key' => api_key}).
              to_return(:status => 302, :headers => { :location => 'http://api.pageclip.io/v1/screenshots/1' })
            result = stub_request(:get, 'http://api.pageclip.io/v1/screenshots/1').
              to_raise(network_exception).then.to_return(:status => 301, :headers => { :location => 'http://s3.amazonaws.com/bucket/1.png' })
            Kernel.should_receive(:sleep).with(1)

            subject.screenshot(url).should eq('http://s3.amazonaws.com/bucket/1.png')
            screenshot.should have_been_requested
            result.should have_been_requested.times(2)
          end

          it 'handles timeouts' do
            validate_success_on_intermittant_exception(Errno::ETIMEDOUT)
          end

          it 'handles end of file errors' do
            validate_success_on_intermittant_exception(EOFError)
          end

          it 'handles connection refused errors' do
            validate_success_on_intermittant_exception(Errno::ECONNREFUSED)
          end
        end

        describe 'prolonged network errors on the screenshot endpoint' do
          def validate_exception_on_prolonged_exception(network_exception, exception)
            screenshot = stub_request(:get, 'http://api.pageclip.io/v1/screenshots/').
              with(:query => {'url' => url, 'api_key' => api_key}).
              to_return(:status => 302, :headers => { :location => 'http://api.pageclip.io/v1/screenshots/1' })
            result = stub_request(:get, 'http://api.pageclip.io/v1/screenshots/1').
              to_raise(network_exception).then.to_raise(network_exception).then.to_raise(network_exception)
            Kernel.should_receive(:sleep).with(1)
            Kernel.should_receive(:sleep).with(2)
            Kernel.should_receive(:sleep).with(3)

            expect { subject.screenshot(url) }.to raise_error(exception)
            screenshot.should have_been_requested
            result.should have_been_requested.times(4)
          end

          it 'handles timeouts' do
            validate_exception_on_prolonged_exception(Errno::ETIMEDOUT, Pageclip::ServiceUnavailableError)
          end

          it 'handles end of file errors' do
            validate_exception_on_prolonged_exception(EOFError, Pageclip::ServiceUnavailableError)
          end

          it 'handles connection refused errors' do
            validate_exception_on_prolonged_exception(Errno::ECONNREFUSED, Pageclip::ServiceUnavailableError)
          end
        end
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
        screenshot = stub_request(:get, 'http://api.pageclip.io/v1/screenshots/').
          with(:query => {'url' => url, 'api_key' => api_key, 'secret' => secret}).
          to_return(:status => 302, :headers => { :location => 'http://api.pageclip.io/v1/screenshots/1' })
        result = stub_request(:get, 'http://api.pageclip.io/v1/screenshots/1').
          to_return(:status => 301, :headers => { :location => 'https://s3.amazonaws.com/bucket/1.png' })

        image_url = subject.screenshot(url)
        screenshot.should have_been_requested
        result.should have_been_requested
        image_url.should eq('https://s3.amazonaws.com/bucket/1.png')
      end

      it 'can override a property' do
        screenshot = stub_request(:get, 'http://api.pageclip.io/v1/screenshots/').
          with(:query => {'url' => url, 'api_key' => api_key, 'secret' => 'b'}).
          to_return(:status => 302, :headers => { :location => 'http://api.pageclip.io/v1/screenshots/1' })
        result = stub_request(:get, 'http://api.pageclip.io/v1/screenshots/1').
          to_return(:status => 301, :headers => { :location => 'https://s3.amazonaws.com/bucket/1.png' })

        image_url = subject.screenshot(url, :secret => 'b')
        screenshot.should have_been_requested
        result.should have_been_requested
        image_url.should eq('https://s3.amazonaws.com/bucket/1.png')
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
        stub_request(:get, 'http://api.pageclip.io/v1/screenshots/').
          with(:query => {'url' => url, 'api_key' => api_key, 'secret' => 'b'}).
          to_return(:status => 302, :headers => { :location => 'http://api.pageclip.io/v1/screenshots/1' })
        stub_request(:get, 'http://api.pageclip.io/v1/screenshots/1').
          to_return(:status => 301, :headers => { :location => 'https://s3.amazonaws.com/bucket/1.png' })

        subject.screenshot(url, :secret => 'b')
        logger.messages.length.should eq(1)
        logger.messages[0].should match(/\[Pageclip 301 [0-9\.]+s\] Requested #{url}/)
      end

      it 'captures a message on failed response' do
        stub = stub_request(:get, 'http://api.pageclip.io/v1/screenshots/').
          with(:query => {'url' => url, 'api_key' => api_key, 'secret' => 'b'}).to_return(:status => 403)

        expect { subject.screenshot(url, :secret => 'b') }.to raise_error(Pageclip::UnauthorizedError)
        logger.messages.length.should eq(1)
        logger.messages[0].should match(/\[Pageclip 403 [0-9\.]+s\] Requested #{url}/)
      end

      it 'captures a message on exception' do
        stub = stub_request(:get, 'http://api.pageclip.io/v1/screenshots/').
          with(:query => {'url' => url, 'api_key' => api_key, 'secret' => 'b'}).to_raise(Timeout::Error)

        expect { subject.screenshot(url, :secret => 'b') }.to raise_error(Pageclip::TimeoutError)
        logger.messages.length.should eq(1)
        logger.messages[0].should match(/\[Pageclip - \?+s\] Requested #{url}/)
      end
    end
  end
end
