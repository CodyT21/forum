ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require 'bcrypt'
require 'pg'

require_relative '../forum'

class Forum < Minitest::Test
  include Rack::Test::Methods

  def setup
    @db = DatabasePersistance.new
    @db.clear

    # test data
    add_new_user('TestUser', 'password')
    @db.add_post('Test Post', 'This is a test post.', 1)
    @db.add_comment_to_post(1, 1, 'Test comment')
  end

  def session
    last_request.env['rack.session']
  end
  
  def test_user_session(username='TestUser')
    user = @db.find_user(username)
    { 'rack.session' => { user: { id: user[:id], username: user[:username] } } }
  end

  def add_new_user(username, password)
    stored_hash = BCrypt::Password.create(password)
    @db.add_user(username, stored_hash)
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
    assert_includes last_response.body, "<p>#{comment[:content]}</p>"
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
    assert_includes last_response.body, "<p>#{comment[:content]}</p>"
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
    add_new_user('TestUser2', 'password')

    get '/posts', {}, test_user_session('TestUser2')
    refute_includes last_response.body, %q(<input type="submit" value="Delete")
    refute_includes last_response.body, %q(<a href="posts/1/edit">Edit</a>)

    @db.add_post('Second Test Post', 'Content for second test post.', 2)
    get '/posts', {}, test_user_session('TestUser2')
    assert_includes last_response.body, %q(<input type="submit" value="Delete")
    assert_includes last_response.body, %q(<a href="/posts/2/edit">Edit</a>)
  end

  def test_render_login
    get '/users/login'
    assert_equal 200, last_response.status
    assert_includes last_response.body, %q(<input name="username" type="text" value="">)
    assert_includes last_response.body, %q(<input name="password" type="password" value="")
  end

  def test_login_user
    post '/users/login', { username: 'TestUser', password: 'password' }
    assert_equal 302, last_response.status
    assert_equal 'Login successful.', session[:message]

    get last_response['Location']
    assert_equal 302, last_response.status

    get last_response['Location']
    assert_includes last_response.body, "<p>Logged in as TestUser</p>"
    assert_includes last_response.body, %q(<input type="submit" value="Logout")
    refute_nil session[:user]
  end

  def test_login_user_invalid_credentials
    post '/users/login', { username: 'TestUser', password: '12345' }
    assert_includes last_response.body, 'Invalid username or password.'
    assert_nil session[:user]
  end

  def test_logout_user
    get '/posts', {}, test_user_session
    refute_nil session[:user]
    assert_includes last_response.body, %q(<input type="submit" value="Logout")
    refute_includes last_response.body, "<button>Login</button>"

    post '/users/logout'
    assert_equal 302, last_response.status
    assert_equal 'You have been logged out succesfully.', session[:message]

    get last_response['Location']
    assert_nil session[:user]
    refute_includes last_response.body, %q(<input type="submit" value="Logout")
    assert_includes last_response.body, "<button>Login</button>"
  end

  def test_render_create_new_user_page
    get '/users/new'
    assert_equal 200, last_response.status
    assert_includes last_response.body, %q(<input type="text" name="username" value="">)
    assert_includes last_response.body, %q(<input type="password" name="password" minlength="8" required>)
  end

  def test_create_new_user
    post '/users', { username: 'TestUser2', password: '12345678' }
    assert_equal 302, last_response.status
    assert_equal 'New user created successfully. Please log in to continue.', session[:message]

    post last_response['Location'], { username: 'TestUser2', password: '12345678' }
    assert_equal 'Login successful.', session[:message]

    get last_response['Location']
    assert_equal 302, last_response.status

    get last_response['Location']
    assert_includes last_response.body, 'Logged in as TestUser2'
    refute_nil session[:user]
  end

  def test_create_new_user_duplicate_username
    post '/users', { username: 'TestUser', password: '12345678' }
    assert_includes last_response.body, 'TestUser already exists. Please enter a different name.'
  end

  def test_create_new_user_invalid_username
    post '/users', { username: 'T', password: '12345678' }
    assert_includes last_response.body, 'Username must be between 2 and 50 characters in length.'
  end
  
  def test_login_redirect_to_original_route
    get '/posts/1/comments'
    assert_equal 302, last_response.status
    assert_equal 'You must be signed in to perform this action.', session[:message]
    
    get last_response['Location']
    assert_includes last_response.body, %q(<input name="username" type="text" value="">)
    assert_includes last_response.body, %q(<input name="password" type="password" value="")
    
    post '/users/login', { username: 'TestUser', password: 'password' }
    assert_equal 302, last_response.status
    assert_equal 'Login successful.', session[:message]
    
    get last_response['Location']
    assert_equal 200, last_response.status
    assert_includes last_response.body, '<p>This is a test post.</p>'
  end
  
  def test_redirect_invalid_user_edit_content
    add_new_user('TestUser2', 'password')
    
    get '/posts/1/edit', {}, test_user_session('TestUser2')
    assert_equal 302, last_response.status
    assert_equal 'Access denied. You are not the creator of this content.', session[:message]
  end
  
  def test_post_pagination
    (2..10).each { |post_num| @db.add_post("Test Post #{post_num}", 'Test post content.', 1) }
    
    get '/posts', {}, test_user_session
    assert_includes last_response.body, 'Test Post 10'
    refute_includes last_response.body, 'Test Post 5'
    assert_includes last_response.body, '<button>Next</button>'
    assert_includes last_response.body, '<button>Last</button>'
    refute_includes last_response.body, '<button>Previous</button>'
    refute_includes last_response.body, '<button>First</button>'
    
    get '/posts?page=2'
    assert_includes last_response.body, 'Test Post 5'
    refute_includes last_response.body, 'Test Post 10'
    assert_includes last_response.body, '<button>Previous</button>'
    assert_includes last_response.body, '<button>First</button>'
    refute_includes last_response.body, '<button>Next</button>'
    refute_includes last_response.body, '<button>Last</button>'
  end
  
  def test_invalid_page
    get '/posts?page=2', {}, test_user_session
    assert_equal 302, last_response.status
    assert_equal 'Page number does not exists.', session[:message]
  end
  
  def test_comment_pagination
    (2..10).each { |comment_num| @db.add_comment_to_post(1, 1, "Test comment #{comment_num}") }
    
    get '/posts/1/comments', {}, test_user_session
    assert_includes last_response.body, 'Test comment 10'
    refute_includes last_response.body, 'Test comment 5'
    assert_includes last_response.body, '<button>Next</button>'
    assert_includes last_response.body, '<button>Last</button>'
    refute_includes last_response.body, '<button>Previous</button>'
    refute_includes last_response.body, '<button>First</button>'
    
    get '/posts/1/comments?page=2'
    assert_includes last_response.body, 'Test comment 5'
    refute_includes last_response.body, 'Test comment 10'
    assert_includes last_response.body, '<button>Previous</button>'
    assert_includes last_response.body, '<button>First</button>'
    refute_includes last_response.body, '<button>Next</button>'
    refute_includes last_response.body, '<button>Last</button>'
  end
end
