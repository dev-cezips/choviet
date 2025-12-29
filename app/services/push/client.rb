module Push
  class Client
    def deliver!(endpoint:, title:, body:, data: {})
      raise NotImplementedError, "Subclasses must implement deliver!"
    end
    
    # Batch delivery for efficiency
    def deliver_batch!(endpoints:, title:, body:, data: {})
      results = []
      endpoints.each do |endpoint|
        results << deliver!(endpoint: endpoint, title: title, body: body, data: data)
      rescue => e
        Rails.logger.error "[PUSH] Failed to deliver to endpoint #{endpoint.id}: #{e.message}"
        results << { endpoint: endpoint, success: false, error: e.message }
      end
      results
    end
  end
end