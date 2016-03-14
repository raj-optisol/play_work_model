require 'factory_girl'


FactoryGirl.define do

  factory :transaction, class: AccountTransactionData do
    kind :liability
    transaction_type :credit
    status :success
    payment_account_id 1
    transaction_id 'ch_1234'
    order_id 1
    amount 1000
    last4 "4242"
    reason "deposit"
        
  end
end


def create_payment_transaction (payment_account_id, order_id=1)
  od = FactoryGirl.create(:transaction, payment_account_id: payment_account_id, order_id: order_id)
  AccountTransactionRepository.find(od.id)
end

def create_withdraw_transaction(payment_account_id, order_id, amount)
  od = FactoryGirl.create(:transaction, payment_account_id: payment_account_id, transaction_type: "debit", transaction_id:nil, order_id:order_id, amount: amount, reason:"card request")
  AccountTransactionRepository.find(od.id)  
end

def create_revenue_transaction(payment_account_id, order_id, amount, options = {})
  od = FactoryGirl.create(:transaction, 
                          options.merge(payment_account_id: payment_account_id, 
                                        kind:"revenue", 
                                        transaction_type: "credit", 
                                        order_id:order_id, 
                                        amount: amount, 
                                        reason:"card request")
                         )
  AccountTransactionRepository.find(od.id)  
end
