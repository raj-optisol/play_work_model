class Importer
  class Errors
    include Enumerable

    def add_error(field, message)
      errors[field] ||= []
      errors[field] << message
      errors
    end

    def remove_errors_for(field)
      errors.delete field
    end

    def each
      if block_given?
        errors.each { |e| yield e }
      else
        errors.each
      end
    end

    def to_h(top_level_key = true)
      if top_level_key
        {errors: errors}
      else
        errors
      end
    end

    def size
      errors.size
    end
    alias :count :size
    alias :length :size

    private

    def errors
      @errors ||= {}
    end
  end
end
