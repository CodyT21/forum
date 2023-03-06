require 'sinatra'
require 'sinatra/content_for'
require 'tilt/erubis'
require 'bcrypt'

require_relative 'database_persistance'

configure do
  enable :sessions
  set :session_secret, 'secret'
  set :erb, :escape_html => true
  set :num_items_to_display, 5
end

configure(:development) do
  require 'sinatra/reloader'
  also_reload 'database_persistance.rb' if development?
end

def valid_credentials?(username, password)
  credentials = @storage.find_user(username)
  return false unless credentials.key?(:username)

  bcrypt_password = BCrypt::Password.new(credentials[:password])
  bcrypt_password == password
end

def user_signed_in?
  session.key?(:user)
end

def require_user_signin
  return if user_signed_in?

  session[:message] = 'You must be signed in to perform this action.'
  session[:referrer] = request.path_info
  redirect '/users/login'
end

before do
  @storage = DatabasePersistance.new(logger)
  @user = session[:user] || {}
end

def error_for_comment(comment)
  return unless comment.empty? || comment =~ /^\s+$/

  'The comment cannot be left blank.'
end

def error_for_post(title, content)
  if !valid_post_title(title)
    'Title must be between 1 and 100 characters.'
  elsif !valid_post_content(content)
    'The post body cannot be left blank.'
  end
end

def valid_post_title(title)
  (1..100).cover?(title.size)
end

def valid_post_content(content)
  !(content.empty? || content =~ /^\s+$/)
end

def error_for_new_user(username, password)
  if !(2..50).cover?(username.size)
    'Username must be between 2 and 50 characters in length.'
  elsif @storage.username_exists?(username)
    "#{username} already exists. Please enter a different name."
  elsif password.size < 8
    'Password must be at least 8 characters long.'
  end
end

# Render home page
get '/' do
  redirect '/posts'
end

get '/posts' do
  @page = params[:page] ? params[:page].to_i : 1

  num_posts = @storage.num_posts
  @last_page = (num_posts / settings.num_items_to_display)
  @last_page += 1 unless (num_posts % settings.num_items_to_display).zero? && num_posts.positive?

  if @page > @last_page
    session[:message] = 'Page number does not exists.'
    redirect '/posts'
  else
    offset = (@page - 1) * settings.num_items_to_display
    @posts = @storage.find_posts(settings.num_items_to_display, offset)
  end

  erb :posts
end

# Render add new post page
get '/posts/new' do
  require_user_signin
  @post = { title: '', content: '' }
  erb :new_post
end

# Render individual post with comments
get '/posts/:post_id' do
  post_id = params[:post_id].to_i
  redirect "/posts/#{post_id}/comments"
end

get '/posts/:post_id/comments' do
  require_user_signin

  post_id = params[:post_id].to_i
  post_ids = @storage.find_posts.map { |p| p[:id] }

  if post_ids.include?(post_id)
    @page = params[:page] ? params[:page].to_i : 1

    num_comments = @storage.num_comments(post_id)
    @last_page = (num_comments / settings.num_items_to_display)
    @last_page += 1 unless (num_comments % settings.num_items_to_display).zero? && num_comments.positive?

    if @page > @last_page
      session[:message] = 'Page number does not exists.'
      redirect "/posts/#{post_id}/comments"
    else
      offset = (@page - 1) * settings.num_items_to_display
      @post = @storage.find_post(post_id, settings.num_items_to_display, offset)
    end

    erb :post
  else
    session[:message] = 'Post does not exist.'
    redirect '/'
  end
end

# Add a new comment to a post
post '/posts/:post_id/comments' do
  post_id = params[:post_id].to_i
  comment = params[:content]

  error = error_for_comment(comment)
  if error
    @page = 1
    num_comments = @storage.num_comments(post_id)
    @last_page = (num_comments / settings.num_items_to_display)
    @last_page += 1 unless (num_comments % settings.num_items_to_display).zero? && num_comments.positive?
    @post = @storage.find_post(post_id, settings.num_items_to_display, 0)

    session[:message] = error
    status 422
    erb :post
  else
    author_id = params[:user_id].to_i
    @storage.add_comment_to_post(post_id, author_id, comment)
    session[:message] = 'Comment added successfully.'

    redirect "/posts/#{post_id}/comments"
  end
end

# Add a new post
post '/posts' do
  title = params[:title].strip
  content = params[:content]

  error = error_for_post(title, content)
  if error
    session[:message] = error
    @post = {}
    @post[:title] = valid_post_title(title) ? title : ''
    @post[:content] = valid_post_content(content) ? content : ''
    status 422
    erb :new_post
  else
    author_id = params[:user_id].to_i
    @storage.add_post(title, content, author_id)
    session[:message] = 'Post added successfully.'

    redirect '/posts'
  end
end

# Delete a post
post '/posts/:post_id/delete' do
  post_id = params[:post_id].to_i
  @storage.delete_post(post_id)
  session[:message] = 'The post was successfully deleted.'

  redirect '/posts'
end

# Delete a comment from a post
post '/posts/:post_id/comments/:comment_id/delete' do
  post_id = params[:post_id].to_i
  comment_id = params[:comment_id].to_i
  @storage.delete_comment(comment_id)
  session[:message] = 'The comment was successfully removed.'

  redirect "/posts/#{post_id}/comments"
end

# Render edit post page
get '/posts/:post_id/edit' do
  require_user_signin

  post_id = params[:post_id].to_i
  @post = @storage.find_post(post_id)

  if @post
    if @post[:author_id] == @user[:id]
      erb :edit_post
    else
      session[:message] = 'Access denied. You are not the creator of this content.'
      redirect '/posts'
    end
  else
    session[:message] = 'Post does not exist.'
    redirect '/'
  end
end

# Edit a post
post '/posts/:post_id' do
  post_id = params[:post_id].to_i
  title = params[:title].strip
  content = params[:content].strip
  @post = @storage.find_post(post_id)

  error = error_for_post(title, content)
  if error
    session[:message] = error
    status 422
    erb :edit_post
  else
    if @post[:title] == title && @post[:content] == content
      session[:message] = 'The post was not changed.'
    else
      @storage.update_post(post_id, title, content)
      session[:message] = 'The post was updated successfully.'
    end
    redirect '/posts'
  end
end

# Render edit comment page
get '/posts/:post_id/comments/:comment_id/edit' do
  require_user_signin

  post_id = params[:post_id].to_i
  comment_id = params[:comment_id].to_i
  @post = @storage.find_post(post_id)
  @comment = @storage.find_comment(comment_id)
  if !@post
    session[:message] = 'Post does not exist.'
    redirect '/posts'
  elsif !@comment || @comment[:post_id] != post_id
    session[:message] = 'Comment does not exist.'
    redirect "/posts/#{post_id}/comments"
  else
    if @comment[:author_id] == @user[:id]
      erb :edit_comment
    else
      session[:message] = 'Access denied. You are not the creator of this content.'
      redirect "/posts/#{post_id}/comments"
    end
  end
end

# Edit a comment
post '/posts/:post_id/comments/:comment_id' do
  post_id = params[:post_id].to_i
  comment_id = params[:comment_id].to_i
  content = params[:content]
  @post = @storage.find_post(post_id)
  @comment = @storage.find_comment(comment_id)

  error = error_for_comment(content)
  if error
    session[:message] = error
    status 422
    erb :edit_comment
  else
    if @comment[:content] == content
      session[:message] = 'The comment was not changed.'
    else
      @storage.update_comment(comment_id, content)
      session[:message] = 'The comment was updated successfully.'
    end
    redirect "/posts/#{post_id}/comments"
  end
end

# Render signin page
get '/users/login' do
  erb :login
end

# Log in a user
post '/users/login' do
  username = params[:username]
  password = params[:password]

  if valid_credentials?(username, password)
    user = @storage.find_user(username)
    session[:user] = { id: user[:id], username: user[:username] }
    session[:message] = 'Login successful.'
    redirect session.delete(:referrer)
  else
    session[:message] = 'Invalid username or password.'
    erb :login
  end
end

# Log Out a user
post '/users/logout' do
  session.delete(:user)
  session[:message] = 'You have been logged out succesfully.'
  redirect '/posts'
end

# Render create user page
get '/users/new' do
  erb :new_user
end

# Create a new user
post '/users' do
  username = params[:username].strip
  password = params[:password].strip

  error = error_for_new_user(username, password)
  if error
    session[:message] = error
    status 422
    erb :new_user
  else
    stored_hash = BCrypt::Password.create(password)
    @storage.add_user(username, stored_hash)
    session[:message] = 'New user created successfully. Please log in to continue.'
    redirect '/users/login'
  end
end
