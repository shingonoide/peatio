# encoding: UTF-8
# frozen_string_literal: true

describe BlockAPI::Ethereum do
  let(:client) { BlockAPI['eth-rinkeby'] }

  around do |example|
    WebMock.disable_net_connect!
    example.run
    WebMock.allow_net_connect!
  end

  describe '#get_block' do
    let(:start_block) { 2610847 }
    let(:end_block) { 2610906 }
    let(:current_block) { 2610847 }
    let(:block_data) { Rails.root.join('spec', 'resources', 'ethereum-data.json') }
    let!(:payment_address) { create(:eth_payment_address, address: '0xdf87837df26801BDcB3602E722ACA82d5beaAb04')}


    subject { client.get_block(current_block) }

    def request_body(block_number, index)
      { jsonrpc: '2.0',
        id:      index + 1,
        method:  'eth_getBlockByNumber',
        params:  [block_number, true]
      }.to_json
    end

    before do
      File.open(block_data) do |f|
        blocks = JSON.load (f)
        blocks.each_with_index  do |blk,index|
          # binding.pry
          stub_request(:post, client.endpoint).with(body: request_body(blk['result']['number'],index)).to_return(body: blk.to_json)
        end
      end
      BlockAPI::Ethereum.any_instance.expects(:latest_block_number).returns(2610906)
    end

    it do
      svc = BlockchainService::Ethereum.new(Blockchain.find_by_key('eth-rinkeby'))
      svc.process_blockchain
      #is_expected.to eq(current_block)
    end
  end
end
