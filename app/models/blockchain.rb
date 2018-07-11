class Blockchain < ActiveRecord::Base
  has_many :currencies, foreign_key: :blockchain_key, primary_key: :key

  def explorer=(hash)
    write_attribute(:explorer_address, hash.fetch('address'))
    write_attribute(:explorer_transaction, hash.fetch('transaction'))
  end

  def confirmations=(hash)
    write_attribute(:deposit_confirmations, hash.fetch('deposit'))
    write_attribute(:withdraw_confirmations, hash.fetch('withdraw'))
  end

  def status
    super&.inquiry
  end

  def case_insensitive?
    !case_sensitive?
  end

  def confirmations_max
    [deposit_confirmations, withdraw_confirmations].max
  end
end

# == Schema Information
# Schema version: 20180708171446
#
# Table name: blockchains
#
#  id                     :integer          not null, primary key
#  key                    :string(255)      not null
#  name                   :string(255)
#  client                 :string(255)
#  server                 :string(255)
#  height                 :integer
#  deposit_confirmations  :integer          default(6), not null
#  withdraw_confirmations :integer          default(6), not null
#  explorer_address       :string(255)
#  explorer_transaction   :string(255)
#  status                 :string(255)
#  case_sensitive         :boolean          default(TRUE), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_blockchains_on_key     (key) UNIQUE
#  index_blockchains_on_status  (status)
#
