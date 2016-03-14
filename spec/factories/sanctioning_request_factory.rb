def create_sanctioning_request(sb, org, issuer, attrs={status: :pending, kind: :club} )
  req = SanctioningRequest.build(attrs)
  req.on_behalf_of = org._data
  req.target = sb._data
  req.issuer = issuer._data
  SanctioningRequestRepository.persist(req)
end

def create_sanctioning_request_product(sb)
  srp = SanctioningRequestProduct.build(kind:'club', amount:'500', sanctioning_body_id:sb.kyck_id)
  SanctioningRequestProductRepository.persist srp
end
