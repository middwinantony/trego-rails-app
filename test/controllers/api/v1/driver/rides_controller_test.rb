require "test_helper"

class Api::V1::Driver::RidesControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get api_v1_driver_rides_index_url
    assert_response :success
  end
end
