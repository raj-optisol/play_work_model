module Cards
  class SummaryCell < Cell::Rails
    cache :player_summary do |args|
      @obj = args[:obj]
      ncmdigest = @obj.player_card_summary_hash
       "#{@obj.kyck_id}/playercard/#{ncmdigest}"
    end

    def player_summary(args)
      @obj = args[:obj]
      render
    end


    cache :staff_summary do |args|
      @obj = args[:obj]
      ncmdigest = @obj.staff_card_summary_hash
       "#{@obj.kyck_id}/staffcard/#{ncmdigest}"
    end

    def staff_summary(args)
      @obj = args[:obj]
      render
    end
  end
end
