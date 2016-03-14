def create_card_product(sb, attrs={})
  defaults = {name: "Card Product", card_type:'player', amount:'18', sanctioning_body_id:sb.kyck_id, age: 14 }.merge(attrs)
  cp = CardProduct.build(defaults)
  CardProductRepository.persist cp
end
