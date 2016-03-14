# encoding: UTF-8
# Represents an email that needs to be sent after cards get approved.
class CardMail < ActiveRecord::Base
  attr_accessible :order_id, :users, :requester, :registrars
end
