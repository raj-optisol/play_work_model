require 'factory_girl'

def create_competition_entry(issuer, competition, division, team, roster, attrs={status: :pending, kind: :request} )
  req = CompetitionEntry.build(attrs)
  req.issuer = issuer._data
  req.competition = competition._data  
  req.division = division._data if division
  req.team = team._data    
  req.roster = roster._data if roster  

  CompetitionEntryRepository.persist!(req)
end

