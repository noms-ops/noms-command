#!rspec

require 'noms/command/urinion/data'

describe NOMS::Command::URInion::Data do
    describe '.parse' do
        context 'when parsing JSON' do
            subject(:url) { NOMS::Command::URInion::Data.parse('data:application/json;charset=UTF-8,{"one":1}') }
            specify { expect(url.host).to be_nil }
            specify { expect(url.scheme).to eq 'data' }
            specify { expect(url.path).to be_nil }
            specify { expect(url.data_encoding).to be_nil }
            specify { expect(url.mime_type).to eq 'application/json' }
            specify { expect(url.character_set).to eq 'UTF-8' }
            specify { expect(url.data).to eq '{"one":1}' }
        end
    end
end
