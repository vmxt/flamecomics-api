# frozen_string_literal: true

require 'logger'
require 'time'

module Observability
  @started_at = Time.now.utc
  @metrics = Hash.new(0)
  @timings = Hash.new { |hash, key| hash[key] = { count: 0, total_ms: 0.0, max_ms: 0.0 } }
  @logger = Logger.new($stdout)

  module_function

  def logger
    @logger
  end

  def increment(metric, by: 1)
    @metrics[metric.to_s] += by
  end

  def measure(metric)
    started = monotonic_time
    yield
  ensure
    observe(metric, (monotonic_time - started) * 1000) if started
  end

  def observe(metric, duration_ms)
    timing = @timings[metric.to_s]
    timing[:count] += 1
    timing[:total_ms] += duration_ms
    timing[:max_ms] = [timing[:max_ms], duration_ms].max
  end

  def snapshot
    {
      started_at: @started_at.iso8601,
      counters: @metrics.dup,
      timings: @timings.transform_values do |timing|
        average = timing[:count].positive? ? timing[:total_ms] / timing[:count] : 0
        {
          count: timing[:count],
          average_ms: average.round(2),
          max_ms: timing[:max_ms].round(2)
        }
      end
    }
  end

  def reset
    @metrics.clear
    @timings.clear
  end

  def monotonic_time
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end
  private_class_method :monotonic_time
end
