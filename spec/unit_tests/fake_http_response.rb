class FakeResponse
  attr_accessor :code, :body, :header

  def initialize(code=200, body='eww, a body', header={})
    @body = body
    @code = code.to_s
    @header = header
  end
end
