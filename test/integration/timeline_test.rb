require "test_helper"

class TimelineTest < ActionDispatch::IntegrationTest
  test "empty timeline shows title, empty copy, add memory, and appearance control" do
    get root_path

    assert_response :success
    assert_select "h1", "Our Memories"
    assert_select "p", "No memories yet."
    assert_select "a", text: "Add Memory"
    assert_select "[data-appearance-control]"
    assert_select ".year-axis", count: 0
  end

  test "default appearance is dark" do
    get root_path

    assert_response :success
    assert_select "html[data-theme=dark]"
  end

  test "appearance toggle persists in the browser without an account" do
    post appearance_path, params: { appearance: "light" }
    assert_redirected_to root_path

    follow_redirect!
    assert_select "html[data-theme=light]"

    get root_path
    assert_select "html[data-theme=light]"
  end
end
