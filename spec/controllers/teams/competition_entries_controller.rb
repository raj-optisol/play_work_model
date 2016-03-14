module Teams
  class CompetitionEntriesController < ApplicationController
    include Roar::Rails::ControllerAdditions
    before_filter :team
    respond_to :json, :html
    layout "org_tabs"

    def index
      respond_to do |format|
        format.html {}
        format.json do
          entry_params
          options = view_context.default_query_options params
          options.merge! entry_params

          action = KyckRegistrar::Actions::GetCompetitionEntries.new(
            current_user,
            @obj
          )
          @entries = action.execute options
          respond_with @entries, represent_items_with: CompetitionEntryRepresenter
        end
      end
    end

    private

    def team
      @entry_obj = params[:start_with] || 'competition'
      if params[:id]
        @competition_entry = CompetitionEntryRepository.find(
          kyck_id: params[:id]
        )
      end

        @team = OrganizationRepository::TeamRepository.find(
          kyck_id: params.fetch(:team_id)
        )

      @entry_obj = params[:start_with] == 'team' ? @team : nil
    end
  end
end
