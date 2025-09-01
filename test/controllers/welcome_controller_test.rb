require "test_helper"

class WelcomeControllerTest < ActionDispatch::IntegrationTest
  test "should get index" do
    get welcome_url
    assert_response :success
    assert_select "h1", "Welcome Back!"
    assert_select "h2", "How are you feeling today?"
  end

  test "should create mood check-in with valid parameters" do
    post welcome_mood_url, params: { 
      mood_check_in: { 
        mood_level: 8, 
        notes: "Feeling great today!" 
      } 
    }
    
    assert_redirected_to welcome_url
    assert_equal "Mood recorded! Thanks for checking in. 😊", flash[:notice]
  end

  test "should not create mood check-in with invalid mood level" do
    post welcome_mood_url, params: { 
      mood_check_in: { 
        mood_level: 15, 
        notes: "Invalid mood" 
      } 
    }
    
    assert_response :unprocessable_content
    # Check that the response contains the welcome page content
    assert_select "h1", "Welcome Back!"
  end

  test "should not create mood check-in without mood level" do
    post welcome_mood_url, params: { 
      mood_check_in: { 
        notes: "No mood level" 
      } 
    }
    
    assert_response :unprocessable_content
    # Check that the response contains the welcome page content
    assert_select "h1", "Welcome Back!"
  end

  test "should create mood check-in with just mood level" do
    post welcome_mood_url, params: { 
      mood_check_in: { 
        mood_level: 5 
      } 
    }
    
    assert_redirected_to welcome_url
    assert_equal "Mood recorded! Thanks for checking in. 😊", flash[:notice]
  end
end
