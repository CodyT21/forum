ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require 'pg'

require_relative '../forum'

class Forum < Minitest::Test
  include Rack::Test::Methods

  def setup
    @db = DatabasePersistance.new
    @db.clear

    # test data
    @db.create_new_category('Test Category', 100)
    @db.add_user('Test User', 'password')
    @db.add_post('Test Post', 'This is a test post.', 1)
    @db.add_comment_to_post(1, 1, 'Test comment')
    session[:username] = 'Test User'
  end

  def session
    last_request.env['rack.session']
  end

  def teardown
    @db.clear
  end

  def app
    Sinatra::Application
  end

  def test_render_home_page
  end

  def test_display_post
  end

  def test_add_new_post
  end

  def test_add_new_post_invalid_title
  end

  def test_add_new_post_invalid_content
  end

  def test_render_post_edit_page
  end

  def test_edit_post
  end

  def test_edit_post_without_change
  end

  def test_delete_post
  end

  def test_add_comment
  end

  def test_add_comment_invalid_content
  end

  def test_render_comment_edit_page
  end

  def test_edit_comment
  end

  def test_edit_comment_without_change
  end
  
  def test_delete_comment
  end

  def test_display_homepage_with_no_posts
  end

  def test_display_post_with_no_comments
  end
end