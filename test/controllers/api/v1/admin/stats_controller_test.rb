require "test_helper"

class Api::V1::Admin::StatsControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get api_v1_admin_stats_index_url
    assert_response :success
  end
end
