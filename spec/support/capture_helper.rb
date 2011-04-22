module CaptureHelper
  # http://pivotallabs.com/users/alex/blog/articles/853-capturing-standard-out-in-unit-tests
  def capture
    output = StringIO.new
    $stderr = output
    yield
    output.string
  ensure
    $stderr = STDERR
  end
end
