module Null
  class User < Naught.build { |config| config.mimic User}
    def gender
      :male
    end
  end
end
