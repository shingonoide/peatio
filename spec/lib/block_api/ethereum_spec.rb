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
    subject { client.get_block(current_block) }

    def request_body(block_number)
      { jsonrpc: '2.0',
        id:      1,
        method:  'eth_getBlockByNumber',
        params:  [block_number, true]
      }.to_json
    end

    before do
      File.open(block_data) do |f|
        blocks = JSON.load (f)
        blocks.each do |blk|
          stub_request(:post, client.endpoint).with(body: request_body(blk['result']['number'])).to_return(body: blk.to_json)
          #binding.pry
        end
      end
    end

    it do
      is_expected.to eq(current_block)
    end
  end
end
