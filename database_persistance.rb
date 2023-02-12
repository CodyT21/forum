require_relative 'database_connection'

class DatabasePersistance
  include DatabaseConnection

  def find_posts
    sql = <<~SQL
      SELECT id, title, content, author_id, creation_date, update_date
        FROM posts
        ORDER BY update_date DESC NULLS LAST, creation_date DESC
    SQL
    result = query(sql)
    return if result.ntuples == 0

    result.map do |tuple|
      tuple_to_hash(tuple)
    end
  end

  def find_post(post_id)
    sql = <<~SQL
      SELECT id, title, content, author_id, creation_date, update_date
        FROM posts
        WHERE id = $1
    SQL
    result = query(sql, post_id)
    return if result.ntuples == 0

    tuple_to_hash(result.first)
  end

  def find_comment(comment_id)
    sql = <<~SQL
      SELECT id, content, creation_date, update_date, author_id
        FROM comments
        WHERE id = $1
    SQL
    result = query(sql, comment_id)
    return if result.ntuples == 0

    tuple = result.first
    { id: tuple['id'].to_i,
      content: tuple['content'],
      date: tuple['creation_date'],
      update_date: tuple['update_date'],
      author_id: tuple['author_id'].to_i,
      author: find_username(tuple['author_id']) 
    }
  end

  def add_comment_to_post(post_id, author_id, comment)
    sql = <<~SQL
      INSERT INTO comments (post_id, author_id, content)
        VALUES ($1, $2, $3)
    SQL
    query(sql, post_id, author_id, comment)
  end

  def add_post(title, content, author_id)
    sql = <<~SQL
      INSERT INTO posts (title, content, author_id)
        VALUES ($1, $2, $3)
    SQL
    query(sql, title, content, author_id)
  end

  def find_user_id(username)
    sql = <<~SQL
      SELECT id
        FROM users
        WHERE username ILIKE $1
    SQL
    result = query(sql, username)
    result.first['id'].to_i
  end

  def delete_post(post_id)
    sql = "DELETE FROM posts WHERE id = $1"
    query(sql, post_id)
  end

  def delete_comment(comment_id)
    sql = "DELETE FROM comments WHERE id = $1"
    query(sql, comment_id)
  end

  def update_post(post_id, title, content)
    current_datetime = Time.new.strftime("%Y-%m-%d %k:%M:%S")
    sql = <<~SQL
      UPDATE posts
        SET title = $1, content = $2, update_date = $3
        WHERE id = $4
    SQL
    query(sql, title, content, current_datetime, post_id)
  end

  def update_comment(comment_id, content)
    current_datetime = Time.new.strftime("%Y-%m-%d %k:%M:%S")
    sql = <<~SQL
      UPDATE comments
        SET content = $1, update_date = $2
        WHERE id = $3
    SQL
    query(sql, content, current_datetime, comment_id)
  end

  private

  def find_post_comments(post_id)
    sql = <<~SQL
      SELECT id, content, creation_date, update_date, author_id
        FROM comments
        WHERE post_id = $1
        ORDER BY update_date DESC NULLS LAST, creation_date DESC
    SQL
    result = query(sql, post_id)
    return [] if result.ntuples == 0

    result.map do |tuple|
      { id: tuple['id'].to_i,
        content: tuple['content'],
        date: tuple['creation_date'],
        update_date: tuple['update_date'],
        author_id: tuple['author_id'].to_i,
        author: find_username(tuple['author_id']) 
      }
    end
  end

  def tuple_to_hash(tuple)
    post_id = tuple['id'].to_i
    user_id = tuple['author_id'].to_i
    comments = find_post_comments(post_id)
    { id: post_id,
      title: tuple['title'],
      content: tuple['content'],
      date: tuple['creation_date'],
      update_date: tuple['update_date'],
      author_id: user_id,
      author: find_username(user_id),
      comments: comments 
    }
  end

  def find_username(user_id)
    sql = "SELECT username FROM users WHERE id = $1"
    result = query(sql, user_id)
    result.first['username']
  end
end

    