
def create_sanction_for_sb_and_item(sb, sanctioned_item, attrs={})
  sanction = sb.sanction(sanctioned_item, attrs)
  SanctionRepository.persist!(sanction)
end
