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
  end

  def session
    last_request.env['rack.session']
  end
  
  def test_user_session
    'rack.session' => { user_id: 'Test User' }
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
    assert_includes last_response.body
    assert_includes last_response.body, post[:title]
    assert_includes last_response.body, post[:author]
  end

  def test_display_post
    post = @db.find_post(1)
    comment = @db.find_comment(1)
    
    get '/posts/1/comments'
    assert_equal 200, last_response.status
    assert_includes last_response.body, "<h2>#{post[:title]}</h2>"
    assert_includes last_response.body, "<p>#{post[:content]}</p>"
    assert_includes last_response.body, "<td>#{comment[:content]}</td>"
    assert_includes last_response.body, "<td>#{comment[:author]}</td>"
    assert_includes last_response.body, "<td>#{comment[:date]}</td>"
  end

  def test_add_new_post_page
    get '/posts/new'
    assert_equal 200, last_response.status
    assert_includes last_response.body, '<h2>Add New Post</h2>'
    assert_includes last_response.body, %q(<input type="text" name="title" value="")
    assert_includes last_response.body, %q(<textarea name="content")
    assert_includes last_response.body, %q(<input type="submit)
  end
  
  def test_add_new_post
    post '/posts', { title: 'New Post', content: 'This is a new post.', user_id: 1 }
    assert_equal 302, last_response.status
    assert_equal 'Post added succesffuly.', session[:message]
    
    new_post = @db.find_post(2)
    get last_response['Location']
    assert_equal 200, last_response.status
    assert_includes last_response.body, post[:title]
    assert_includes last_response.body, post[:author]
  end

  def test_add_new_post_invalid_title
    post '/posts', { title: '', content: 'This is a new post.', user_id: 1 }
    assert_equal last_response.body, 'Title must be between 1 and 100 characters.'
  end

  def test_add_new_post_invalid_content
    post '/posts', { title: 'New Post', content: '', user_id: 1 }
    assert_equal last_response.body, 'Posts must have at least one character of content.'
  end

  def test_render_post_edit_page
    post = @db.find_post(1)
    
    get '/posts/1/edit'
    assert_equal 200, last_response.status
    assert_includes last_response.body, "<h2>Editing Post: #{post[:title]}</h2>"
    assert_includes last_response.body, %Q(<input type="text" name="title" value="#{post[:title]}")
    assert_includes last_response.body, "#{post[:content]}</textarea>"
    assert_includes last_response.body, %q(<input type="submit)
  end

  def test_edit_post
    original_post = @db.find_post(1)
    post '/posts/1', { title: 'New Title', content: 'This is an updated test post.', user_id: 1 }
    assert_equal 302, last_response.status
    assert_equal 'The post was updated successfully.', session[:message]
    
    updated_post = @db.find_post(1)
    get last_response['Location']
    assert_equal 200, last_response.status
    refute_includes last_response.body, original_post[:title]
    assert_includes last_response.body, updated_post[:title]
    refute_includes last_response.body, original_post[:content]
    assert_includes last_response.body, updated_post[:content]
    assert_includes last_response.body, original_post[:date]
    assert_includes last_response.body, updated_post[:update_date]
  end

  def test_edit_post_without_change
    post '/posts/1', { title: 'Post Title', content: 'This is a test post.', user_id: 1 }
    assert_equal 302, last_response.status
    assert_equal 'The post was not changed.', session[:message]
    
    get last_response['Location']
    assert_equal 200, last_response.status
  end

  def test_delete_post
    post = @db.find_post(1)
    
    post '/posts/1/delete'
    assert_equal 302, last_response.status
    assert_equal 'The post was successfully deleted.', session[:message]
    
    get last_response['Location']
    refute_includes last_response.body, post[:title]
    assert_includes last_response.body, 'No posts to display.'
  end

  def test_add_comment
    post = @db.find_post(1)
    
    get '/posts/1/comments'
    assert_includes last_response.body, %q(<textarea name="content")
    assert_includes last_response.body, %q(<input type="submit")
    
    post '/posts/1/comments', { comment: 'This is a test comment.', user_id: 1 }
    assert_equal 302, last_response.status
    assert_equal 'Comment added successfully.', session[:message]
    
    comment = @db.find_comment(2)
    get last_response['Location']
    assert_includes last_response.body, "<td>#{comment[:content]}</td>"
  end

  def test_add_comment_invalid_content
    post '/posts/1/comments', { comment: '', user_id: 1 }
    assert_inclues last_response.body, 'Comment cannot be left empty.'
  end

  def test_render_comment_edit_page
    post = @db.find_post(1)
    comment = @db.find_comment(1)
    
    get '/posts/1/comments/1/edit'
    assert_equal 200, last_response.status
    assert_includes last_response.body, "<h2>Editing Comment for Post: #{post[:title]}</h2>"
    assert_includes last_response.body, "#{comment[:content]}</textarea>"
    assert_includes last_response.body, %q(<input type="submit)
  end

  def test_edit_comment
    original_comment = @db.find_comment(1)
    post '/posts/1/comments', { content: 'Updated test comment', user_id: 1 }
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
    post '/posts/1/comments', { content: 'Test comment', user_id: 1 }
    assert_equal 302, last_response.status
    assert_equal 'The comment was not changed.', session[:message]
    
    get last_response['Location']
    assert_equal 200, last_response.status
  end
  
  def test_delete_comment
    comment = @db.find_comment(1)
    
    post '/posts/1/delete'
    assert_equal 302, last_response.status
    assert_equal 'The comment was successfully removed.', session[:message]
    
    get last_response['Location']
    refute_includes last_response.body, comment[:content]
    assert_includes last_response.body, 'No comments to display.'
  end
  
  def test_invalid_post_id
    get '/posts/10/comments'
    assert_equal 302, last_response.status
    assert_equal 'Post does not exist.', session[:message]
  end
  
  def test_invalid_comment_id
    get '/posts/1/comments/5/edit'
    assert_equal 302, last_response.status
    assert_equal 'Comment does not exist.', session[:message]
  end
  
  def test_invalid_user_edit_post
  end
end
