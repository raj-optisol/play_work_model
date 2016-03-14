module Null
  class Document < Naught.build { |config| config.mimic Document}

    def reviewed?
      false
    end
  end
end
