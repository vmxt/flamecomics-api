# frozen_string_literal: true

require_relative 'observability'

class RequestLogger
  def initialize(app)
    @app = app
  end

  def call(env)
    started = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    status, headers, body = @app.call(env)
    duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started) * 1000).round(2)

    Observability.increment('requests.total')
    Observability.increment("responses.status.#{status}")
    Observability.observe('requests.duration', duration_ms)
    Observability.logger.info(
      method: env['REQUEST_METHOD'],
      path: env['PATH_INFO'],
      status: status,
      duration_ms: duration_ms
    )

    [status, headers, body]
  end
end
