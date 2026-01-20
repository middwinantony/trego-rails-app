require "test_helper"

class Api::V1::PaymentsControllerTest < ActionDispatch::IntegrationTest
  test "should get show" do
    get api_v1_payments_show_url
    assert_response :success
  end
end
