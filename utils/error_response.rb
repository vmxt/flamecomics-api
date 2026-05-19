# frozen_string_literal: true

module ErrorResponse
  module_function

  def build(message, code:, source:)
    {
      error: message,
      code: code,
      source: source
    }
  end
end
