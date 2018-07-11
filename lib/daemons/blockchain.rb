# encoding: UTF-8
# frozen_string_literal: true

require File.join(ENV.fetch('RAILS_ROOT'), 'config', 'environment')

running = true
Signal.trap(:TERM) { running = false }

while running
  Blockchain.where(key: 'eth-rinkeby', status: 'active').each do |bc|
    break unless running
    Rails.logger.info { "Processing #{bc.name} blocks." }
    client    = BlockAPI[bc.key]
    processed = 0

    # TODO: Call BlockchainService here passing blockchain bc
    #
    Rails.logger.info { "Processing #{bc.name} blocks." }
  rescue => e
    report_exception(e)
  end
  Kernel.sleep 5
end
