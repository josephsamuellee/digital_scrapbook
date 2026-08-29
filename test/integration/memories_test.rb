require "test_helper"

class MemoriesTest < ActionDispatch::IntegrationTest
  test "add memory placeholder is reachable from the timeline" do
    get new_memory_path

    assert_response :success
    assert_select "h1", "Add Memory"
  end
end
