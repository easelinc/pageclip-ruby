module Pageclip
  class Error < RuntimeError
  end

  class TimeoutError < Error
  end

  class UnauthorizedError < Error
  end

  class RateLimitedError < Error
  end

  class ScreenshotError < Error
  end
end
