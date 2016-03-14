class MerchantAccountData < BaseModel::Data

  property :merchant_id
  property :rate, default: "0.029"
  property :per_transaction, default: "0.3"
  
end