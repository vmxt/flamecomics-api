module Utils
  class Response
    def self.make_response_object(data, status = 200)
      { status: status, data: data || nil }
    end
  end
end
