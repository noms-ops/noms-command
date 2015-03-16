#!/usr/bin/env rspec

require 'noms/command/application'

describe NOMS::Command::Application do

    describe '.render!' do

        subject(:doc) do
            NOMS::Command::Application.
                new(NOMS::Command::Window.new($0), <<'EOF', %w(echo one two three))
data:application/json,{
  "$doctype":"noms-v2",
  "$body": ["Usage:","   noms echo <string>"],
  "$argv": ["echo", "one", "two", "three"],
  "$script": [ "window.document.body = window.document.argv.slice(1).join(' ')" ]
}
EOF
        end

        it "should have initial output" do
            doc.fetch!
            expect(doc.display).to eq "Usage:\n   noms echo <string>"
        end

        it "should render by echoing arguments" do
            doc.fetch!
            doc.render!
            expect(doc.display).to eq "one two three"
        end

    end
end
