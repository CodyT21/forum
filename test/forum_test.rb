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
    @db.add_user('Test User', 'password')
    @db.add_post('Test Post', 'This is a test post.', 1)
    @db.add_comment_to_post(1, 1, 'Test comment')
  end

  def session
    last_request.env['rack.session']
  end
  
  def test_user_session
    user = @db.find_user('Test User', 'password')
    { 'rack.session' => { user: user } }
  end

  def teardown
    @db.clear
  end

  def app
    Sinatra::Application
  end

  def test_render_home_page
    post = @db.find_post(1)
    
    get '/'
    assert_equal 302, last_response.status
    
    get last_response['Location']
    assert_equal 200, last_response.status
    assert_includes last_response.body, '<h1>Forum Posts</h1>'
    assert_includes last_response.body, post[:title]
    assert_includes last_response.body, post[:author]
  end

  def test_display_post
    post = @db.find_post(1)
    comment = @db.find_comment(1)
    
    get '/posts/1', {}, test_user_session
    assert_equal 302, last_response.status
    
    get last_response['Location'], {}
    assert_equal 200, last_response.status
    assert_includes last_response.body, "<h2>#{post[:title]}</h2>"
    assert_includes last_response.body, "<p>#{post[:content]}</p>"
    assert_includes last_response.body, "<td>#{comment[:content]}</td>"
    assert_includes last_response.body, "<td>#{comment[:author]}</td>"
    assert_includes last_response.body, "<td>#{comment[:date]}</td>"
  end

  def test_add_new_post_page
    get '/posts/new', {}, test_user_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, '<h2>Add a New Post</h2>'
    assert_includes last_response.body, %q(<input type="text" name="title" value="")
    assert_includes last_response.body, %q(<textarea name="content")
    assert_includes last_response.body, %q(<input type="submit")
  end
  
  def test_add_new_post
    post '/posts', { title: 'New Post', content: 'This is a new post.', user_id: 1 }, test_user_session
    assert_equal 302, last_response.status
    assert_equal 'Post added successfully.', session[:message]
    
    new_post = @db.find_post(2)
    get last_response['Location']
    assert_equal 200, last_response.status
    assert_includes last_response.body, new_post[:title]
    assert_includes last_response.body, new_post[:author]
  end

  def test_add_new_post_invalid_title
    post '/posts', { title: '', content: 'This is a new post.', user_id: 1 }, test_user_session
    assert_includes last_response.body, 'Title must be between 1 and 100 characters.'
  end

  def test_add_new_post_invalid_content
    post '/posts', { title: 'New Post', content: '', user_id: 1 }, test_user_session
    assert_includes last_response.body, 'Posts must have at least one character of content.'
  end

  def test_render_post_edit_page
    post = @db.find_post(1)
    
    get '/posts/1/edit', {}, test_user_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, "<h2>Editing Post: #{post[:title]}</h2>"
    assert_includes last_response.body, %Q(<input type="text" name="title" value="#{post[:title]}")
    assert_includes last_response.body, "#{post[:content]}</textarea>"
    assert_includes last_response.body, %q(<input type="submit")
  end

  def test_edit_post
    original_post = @db.find_post(1)
    post '/posts/1', { title: 'New Title', content: 'This is an updated test post.', user_id: 1 }, test_user_session
    assert_equal 302, last_response.status
    assert_equal 'The post was updated successfully.', session[:message]
    
    updated_post = @db.find_post(1)
    get last_response['Location']
    assert_equal 200, last_response.status
    refute_includes last_response.body, original_post[:title]
    assert_includes last_response.body, updated_post[:title]
    assert_includes last_response.body, original_post[:date]
    assert_includes last_response.body, updated_post[:update_date]
  end

  def test_edit_post_without_change
    post '/posts/1', { title: 'Test Post', content: 'This is a test post.', user_id: 1 }, test_user_session
    assert_equal 302, last_response.status
    assert_equal 'The post was not changed.', session[:message]
    
    get last_response['Location']
    assert_equal 200, last_response.status
  end

  def test_delete_post
    post = @db.find_post(1)
    
    post '/posts/1/delete', {}, test_user_session
    assert_equal 302, last_response.status
    assert_equal 'The post was successfully deleted.', session[:message]
    
    get last_response['Location']
    refute_includes last_response.body, post[:title]
    assert_includes last_response.body, 'No posts to display.'
  end

  def test_add_comment
    post = @db.find_post(1)
    
    get '/posts/1/comments', {}, test_user_session
    assert_includes last_response.body, %q(<textarea name="content")
    assert_includes last_response.body, %q(<input type="submit")
    
    post '/posts/1/comments', { content: 'This is a test comment.', user_id: 1 }
    assert_equal 302, last_response.status
    assert_equal 'Comment added successfully.', session[:message]
    
    comment = @db.find_comment(2)
    get last_response['Location']
    assert_includes last_response.body, "<td>#{comment[:content]}</td>"
  end

  def test_add_comment_invalid_content
    post '/posts/1/comments', { content: '', user_id: 1 }, test_user_session
    assert_includes last_response.body, 'Comment cannot be left empty.'
  end

  def test_render_comment_edit_page
    post = @db.find_post(1)
    comment = @db.find_comment(1)
    
    get '/posts/1/comments/1/edit', {}, test_user_session
    assert_equal 200, last_response.status
    assert_includes last_response.body, "<h2>Editing Comment for Post: #{post[:title]}</h2>"
    assert_includes last_response.body, "#{comment[:content]}</textarea>"
    assert_includes last_response.body, %q(<input type="submit")
  end

  def test_edit_comment
    original_comment = @db.find_comment(1)
    post '/posts/1/comments/1', { content: 'Updated test comment', user_id: 1 }, test_user_session
    assert_equal 302, last_response.status
    assert_equal 'The comment was updated successfully.', session[:message]
    
    updated_comment = @db.find_comment(1)
    get last_response['Location']
    assert_equal 200, last_response.status
    refute_includes last_response.body, original_comment[:content]
    assert_includes last_response.body, updated_comment[:content]
    assert_includes last_response.body, original_comment[:date]
    assert_includes last_response.body, updated_comment[:update_date]
  end

  def test_edit_comment_without_change
    post '/posts/1/comments/1', { content: 'Test comment', user_id: 1 }, test_user_session
    assert_equal 302, last_response.status
    assert_equal 'The comment was not changed.', session[:message]
    
    get last_response['Location']
    assert_equal 200, last_response.status
  end
  
  def test_delete_comment
    comment = @db.find_comment(1)
    
    post '/posts/1/comments/1/delete', {}, test_user_session
    assert_equal 302, last_response.status
    assert_equal 'The comment was successfully removed.', session[:message]
    
    get last_response['Location']
    refute_includes last_response.body, comment[:content]
    assert_includes last_response.body, 'No comments to display.'
  end
  
  def test_invalid_post_id
    get '/posts/10/comments', {}, test_user_session
    assert_equal 302, last_response.status
    assert_equal 'Post does not exist.', session[:message]
  end
  
  def test_invalid_comment_id
    get '/posts/1/comments/5/edit', {}, test_user_session
    assert_equal 302, last_response.status
    assert_equal 'Comment does not exist.', session[:message]
  end
  
  def test_invalid_user_edit_or_delete_post
    @db.add_user('Test User 2', 'password')
    new_user = @db.find_user('Test User 2', 'password')
    get '/posts', {}, { 'rack.session' => { user: new_user } }
    refute_includes last_response.body, %q(<input type="submit" value="Delete")
    refute_includes last_response.body, %q(<a href="posts/1/edit">Edit</a>)

    @db.add_post('Second Test Post', 'Content for second test post.', 2)
    get '/posts', {}, { 'rack.session' => { user: new_user } }
    assert_includes last_response.body, %q(<input type="submit" value="Delete")
    assert_includes last_response.body, %q(<a href="/posts/2/edit">Edit</a>)
  end

  def test_render_login
  end

  def test_login_user
  end

  def test_footer_with_login
  end

  def test_footer_without_login
  end

  def test_create_new_user
  end

  def test_create_new_user_duplicate_username
  end

  def test_create_new_user_invalid_username
  end
end
