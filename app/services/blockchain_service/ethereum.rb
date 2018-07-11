# encoding: UTF-8
# frozen_string_literal: true

module BlockchainService
  class Ethereum < BaseService

    def process_blockchain
      current_block   = @blockchain.height || 0
      latest_block    = @client.latest_block_number
      # binding.pry
      while current_block <= latest_block
        #binding.pry
        block_json          = @client.get_block(current_block)
        # binding.pry
        if block_json
          deposits = []
          transactions        = block_json.fetch('transactions')
          transactions.each do |tx|

            # Skip contract creation transactions.
            next if tx['to'].blank?
            # Skip outcomes (less than zero) and contract transactions (zero).
            next if tx.fetch('value').hex.to_d <= 0
            # Search Wallet or PaymentAddress for deposit address
            #currency = find_currency(tx)
            #next unless currency

            # WARNING: shitty code {
            address = @client.to_address(tx)
            address_in_db = find_address_in_db(address)
            puts "address in db #{address_in_db}" if address_in_db.present?
            if address_in_db.present?
              trn = @client.build_deposit(tx, block_json, latest_block, address_in_db[:currency])
              trn.fetch(:enties).each_with_index do |entry, i|
                # }

                deposits << {
                    txid:           trn[:id],
                    address:        entry[:address],
                    amount:         entry[:amount],
                    member:         address_in_db[:member],
                    currency:       address_in_db[:currency],
                    txout:          i,
                    confirmations:  trn[:confirmations]
                }
              end
            end
            # }

            #### Save deposits for single block.
          end
          deposits.each { |hash| Deposits::Coin.create! hash }
        end

        current_block += 1
        @blockchain.update(height: current_block)
      end
    end

    private

    # TODO: make this method beautiful
    def find_address_in_db(address)
      pa = PaymentAddress.find_by(address: address ,currency_id: @blockchain.currencies.pluck(:id))

      # TODO: check if Deposit doesn't exist
      # example deposit_coin.rb
      # def deposit_entry_processable?(currency, tx, entry, index)
      #   PaymentAddress.where(currency: currency, address: entry[:address]).exists? &&
      #       !Deposit.where(currency: currency, txid: tx[:id], txout: index).exists?
      # end
      #
      return nil if pa.blank?
      {
        member: pa.account.member,
        currency: pa.currency
      }
    end
  end
end