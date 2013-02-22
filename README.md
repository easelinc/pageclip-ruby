# pageclip-ruby

A simple gem to interface with pageclip API.

## Example

```
require 'pageclip'

Pageclip.configure do |config|
  config.api_key = 'your-secret-api-key'
end

begin
  data = Pageclip.screenshot('http://www.example.com')
  File.open('screenshot.png') do |f|
    f.write(data)
  end
  puts 'The screenshot is done!'
rescue Pageclip::Timeout
  puts 'Sorry I couldn't find a screenshot
rescue Pageclip::UnauthorizedError
  puts 'You don't have a valid API key'
rescue Pageclip::RateLimitedError
  puts 'Too many requests, wait before trying again'
rescue Pageclip::Error
  puts 'Unknown error'
end
```

## Global configuration

 * api_key - Your API key.
 * job_defaults - This set of options will be used for all requests and
   can be overriden by specifying any of the properties as options to
   #screenshot.

## Job Parameters

 * viewport_width, viewport_height - Controls the size of viewport of
   the browser in pixels. It defaults to 1024x768 (permitted: 0-1024).
 * canvas_width, canvas_height - Controls the size in pixels of the
   entire page. If undefined it will screenshot the entire page.
   (permitted: 0-10000)
 * thumbnail_width, thumbnail_height - Controls the size in pixels of the
   final screenshot. If undefined it will result in a screenshot at the
   same size as the canvas. (permitted: 0-3000)
 * secret - Sets a custom header ('X-Secret') so you can authenticate
   the request coming to one of your private pages. If undefined the
   header will not be sent. (any string less than 256 characters)
 * timeout - Wait x number of seconds from starting to load the page to
   take a screenshot. If undefined it will load as soon as the page as
   finished loading (permitted: 0-55).
