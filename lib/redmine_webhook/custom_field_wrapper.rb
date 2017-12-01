module RedmineWebhook
  class CustomFieldWrapper
    
    def initialize(field)
      @field = field
    end

    def to_hash
      return nil unless @field
      {
        :id => @field.custom_field.id,
        :name => @field.custom_field.name,
        :value => @field.value
      }
    end
  end
end
