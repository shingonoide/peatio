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
    context 'single deposit was created during blockchain proccessing' do
      # TODO: create blockchain with start_block because now it's hardcoded in factory.
      let(:start_block) { 2610847 }
      let(:latest_block) { 2610906 }
      let(:blockchain) { Blockchain.find_by_key('eth-rinkeby') }
      let(:block_data) { Rails.root.join('spec', 'resources', 'ethereum-data.json') }
      let!(:payment_address) { create(:eth_payment_address, address: '0xdf87837df26801BDcB3602E722ACA82d5beaAb04')}


      # subject { client.get_block(current_block) }

      def request_body(block_number, index)
        { jsonrpc: '2.0',
          id:      index + 1, # TODO:
          method:  :eth_getBlockByNumber,
          params:  [block_number, true]
        }.to_json
      end

      # TODO: make this before clean.
      before do
        File.open(block_data) do |f|
          blocks = JSON.load(f)
          blocks.each_with_index do |blk, index|
            stub_request(:post, client.endpoint).with(body: request_body(blk['result']['number'],index)).to_return(body: blk.to_json)
          end
        end
        BlockAPI::Ethereum.any_instance.expects(:latest_block_number).returns(latest_block)
        BlockchainService.new(blockchain).process_blockchain
      end

      subject { Deposits::Coin.where(currency_id: :eth).first }

      it 'creates single deposit' do
        expect(Deposits::Coin.where(currency_id: :eth).count).to eq 1
      end

      it 'creates deposit with correct amount' do
        # '0x162ea854d0fc000' - transaction 'value' from ethereum-data.json
        expect(subject.amount).to eq '0x162ea854d0fc000'.hex.to_d / Currency.find_by_id(:eth).base_factor
      end

      it 'creates deposit with correct address' do
        # '0xdf87837df26801bdcb3602e722aca82d5beaab04' - transaction 'to' from ethereum-data.json
        expect(subject.address).to eq '0xdf87837df26801bdcb3602e722aca82d5beaab04'
      end

      it 'creates deposit with correct txid' do
        # '0x03e25b5339de3b453e6f56391410ecaff10e332f34b7894382846f70a9755302' -
        # transaction 'hash' from ethereum-data.json
        expect(subject.txid).to eq '0x03e25b5339de3b453e6f56391410ecaff10e332f34b7894382846f70a9755302'
      end

      it 'creates deposit with correct confirmations amount' do
        # TODO.
        # expect(subject.confirmations).to eq latest_block - ?
      end
    end
  end
end
