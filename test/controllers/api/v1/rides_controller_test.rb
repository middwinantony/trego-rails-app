require "test_helper"

class Api::V1::RidesControllerTest < ActionDispatch::IntegrationTest
  test "should get create" do
    get api_v1_rides_create_url
    assert_response :success
  end

  test "should get show" do
    get api_v1_rides_show_url
    assert_response :success
  end
end
