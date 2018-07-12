# encoding: UTF-8
# frozen_string_literal: true

describe BlockchainService do

  around do |example|
    WebMock.disable_net_connect!
    example.run
    WebMock.allow_net_connect!
  end

  describe 'BlockAPI::Ethereum' do
    let(:block_data) do
      Rails.root.join('spec', 'resources', block_file_name)
        .yield_self { |file_path| File.open(file_path) }
        .yield_self { |file| JSON.load(file) }
    end

    let(:start_block)   { block_data.first['result']['number'].hex }
    let(:latest_block)  { block_data.last['result']['number'].hex }

    let(:blockchain) do
      Blockchain.find_by_key('eth-rinkeby')
        .tap { |b| b.update(height: start_block)}
    end
    let(:currency) { Currency.find_by_id(:eth) }

    let!(:payment_address) do
      create(:eth_payment_address, address: '0xdf87837df26801BDcB3602E722ACA82d5beaAb04')
    end

    let(:client) { BlockAPI[blockchain.key] }

    def request_body(block_number, index)
      { jsonrpc: '2.0',
        id:      index + 1, # json_rpc_call_id increments on each request.
        method:  :eth_getBlockByNumber,
        params:  [block_number, true]
      }.to_json
    end

    context 'single deposit was created during blockchain proccessing' do
      # File with fake json rpc data.
      let(:block_file_name) { 'ethereum-data.json' }

      before do
        # Mock requests and methods.
        client.class.any_instance.stubs(:latest_block_number).returns(latest_block)
        block_data.each_with_index do |blk, index|
          stub_request(:post, client.endpoint)
            .with(body: request_body(blk['result']['number'],index))
            .to_return(body: blk.to_json)
        end
        # Process blockchain data.
        BlockchainService.new(blockchain).process_blockchain
      end

      subject { Deposits::Coin.where(currency: currency).first }

      it 'creates single deposit' do
        expect(Deposits::Coin.where(currency: currency).count).to eq 1
      end

      it 'creates deposit with correct amount' do
        # '0x162ea854d0fc000' - transaction 'value' from ethereum-data.json
        expect(subject.amount).to eq '0x162ea854d0fc000'.hex.to_d / currency.base_factor
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

      context 'nothing was broken if we process same data twice' do
        before do
          blockchain.update(height: start_block)
        end

        it 'doesn\'t change deposit' do
          expect(blockchain.height).to eq start_block
          expect{ BlockchainService.new(blockchain).process_blockchain}.not_to change{subject}
          expect(blockchain.height).not_to eq start_block
        end
      end

    end
  end
end
