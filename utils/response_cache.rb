# frozen_string_literal: true

module ResponseCache
  DEFAULT_TTL = 180

  @store = {}

  module_function

  def fetch(key, ttl: DEFAULT_TTL)
    now = Time.now
    cached = @store[key]
    return cached[:value] if cached && cached[:expires_at] > now

    value = yield
    @store[key] = { value: value, expires_at: now + ttl }
    value
  end

  def stats
    now = Time.now
    prune_expired(now)

    {
      count: @store.size,
      default_ttl_seconds: DEFAULT_TTL,
      keys: @store.map do |key, entry|
        {
          key: key,
          expires_in_seconds: [(entry[:expires_at] - now).ceil, 0].max
        }
      end
    }
  end

  def clear
    @store.clear
  end

  def prune_expired(now = Time.now)
    @store.delete_if { |_key, entry| entry[:expires_at] <= now }
  end
end
