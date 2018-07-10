# encoding: UTF-8
# frozen_string_literal: true

module Services
  class BlockchainService

    def initialize(blockchain)
      @blockchain = blockchain
      @client     = BlockAPI[blockchain.client]
    end

    def current_height
      @blockchain.height
    end

    def process_blockchain
      current_block   = @blockchain.height || 0
      latest_block    = @client.latest_block_number

      while current_block <= latest_block
        deposits = []
        block_json          = @client.block_information("0x" + current_block.to_s(16))
        if block_json
          transactions        = block_json.fetch('transactions')
          transactions.each do |tx|

            # Skip contract creation transactions.
            next if tx['to'].blank?
            # Skip outcomes (less than zero) and contract transactions (zero).
            next if tx.fetch('value').hex.to_d <= 0
            # Search Wallet or PaymentAddress for deposit address
            currency = find_currency(tx)
            next unless currency

            address = BlockAPI[currency.code].to_address(tx)
            deposits << BlockAPI[currency.code].build_deposit(tx, block_json, latest_block ) if Wallet.active.where(address: address, kind: 'deposit').exists? || PaymentAddress.where(currency: currency, address: address).exists?
          end

          # sql transaction to update the height and INSERT all Deposits / Withdrawal founder
        end

        current_block += 1
      end
    end

    private

    def find_currency(tx)
      if tx['input'].blank? || tx['input'].hex <= 0
        @client.currency
      else
        Currency.find{|c| @client.normalize_address(tx['to']) == c.erc20_contract_address}
      end
    end

  end
end