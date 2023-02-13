require 'sinatra'
# require 'sinatra/content_for'
require 'tilt/erubis'
# require 'bcrypt'

require_relative 'database_persistance'

configure do
  enable :sessions
  set :session_secret, 'secret'
end

configure(:development) do
  require 'sinatra/reloader'
  also_reload 'database_persistance.rb' if development?
end

helpers do
  def current_user_id
    session[:username] = 'admin' # need to flush this out and implement this for many users
    username = session[:username]
    @storage.find_user_id(username)
  end
end

def load_user_credentials
  user_path = if ENV['RACK_ENV'] == 'test'
                File.expand_path('..test/users/', __FILE__)
              else
                File.expand_path('..users', __FILE__)
              end
  YAML.load_file(File.join(user_path, 'users.yml'))
end

def valid_credentials?(user_id, password)
  credentials = load_user_credentials
  return false unless credentials.key?(user_id)
    
  bcrypt_password = BCrypt::Password.new(credentials[user_id])
  bcrypt_password == password
end

# def user_signed_in?
#   session.key?(:user_id)
# end

# def require_user_signin
#   unless user_signed_in?
#     session[:message] = 'You must be signed in to perform that action.'
#     redirect '/'
#   end
# end

before do
  @storage = DatabasePersistance.new()
end

def error_for_comment(comment)
  if comment.size < 1
    'Comment cannot be left empty.'
  else
    return
  end
end

def error_for_post(title, content)
  if !(1..100).cover?(title.size)
    'Title must be between 1 and 100 characters.'
  elsif content.size < 1
    'Posts must have at least one character of content.'
  else
    return
  end
end

# Render home page
get '/' do
  redirect '/posts'
end

get '/posts' do
  @posts = @storage.find_posts

  erb :posts
end

# Render add new post page
get '/posts/new' do
  erb :new_post
end

# Render individual post with comments
get '/posts/:post_id' do
  post_id = params[:post_id].to_i
  redirect "/posts/#{post_id}/comments"
end

get '/posts/:post_id/comments' do
  post_id = params[:post_id].to_i
  @post = @storage.find_post(post_id)

  if @post
    erb :post
  else
    session[:message] = 'Post does not exist.'
    redirect '/'
  end
end

# Add a new comment to a post
post '/posts/:post_id/comments' do
  post_id = params[:post_id].to_i
  comment = params[:comment].strip
  
  error = error_for_comment(comment)
  if error
    @post = @storage.find_post(post_id)
    session[:message] = error
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
  content = params[:content].strip

  error = error_for_post(title, content)
  if error
    session[:message] = error
    erb :new_post
  else
    author_id = params[:user_id].to_i
    @storage.add_post(title, content, author_id)

    redirect '/posts'
  end
end

# Delete a post
post '/posts/:post_id/delete' do
  post_id = params[:post_id].to_i
  @storage.delete_post(post_id)
  session[:message] = "The post was successfully deleted."

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
  post_id = params[:post_id].to_i
  @post = @storage.find_post(post_id)

  if @post
    erb :edit_post
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
  user_id = params[:user_id].to_i
  @post = @storage.find_post(post_id)

  error = error_for_post(title, content)
  if error
    session[:message] = error
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
  post_id = params[:post_id].to_i
  comment_id = params[:comment_id].to_i
  @post = @storage.find_post(post_id)
  @comment = @storage.find_comment(comment_id)
  if @post && @comment
    erb :edit_comment
  elsif !@post
    session[:message] = 'Post does not exist.'
    redirect '/posts'
  else
    session[:message] = 'Comment does not exist.'
    redirect "/posts/#{post_id}/comments"
  end
end

# Edit a comment
post '/posts/:post_id/comments/:comment_id' do
  post_id = params[:post_id].to_i
  comment_id = params[:comment_id].to_i
  content = params[:comment].strip
  user_id = params[:user_id].to_i
  @post = @storage.find_post(post_id)
  @comment = @storage.find_comment(comment_id)

  error = error_for_comment(content)
  if error
    session[:message] = error
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
