require "test_helper"

class ProductionAssetsTest < ActiveSupport::TestCase
  test "production enables Propshaft asset serving from Puma" do
    source = Rails.root.join("config/environments/production.rb").read

    assert_match(/config\.assets\.server\s*=\s*true/, source)
    assert_match(/config\.public_file_server\.enabled\s*=\s*true/, source)
  end
end
