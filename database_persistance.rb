require_relative 'database_connection'

class DatabasePersistance
  include DatabaseConnection

  def find_posts(limit=nil, offset=nil)
    sql = <<~SQL
      SELECT p.*, u.username
        FROM posts p
        LEFT JOIN users u ON p.author_id = u.id
        ORDER BY p.update_date DESC, p.id DESC
        LIMIT $1 OFFSET $2
    SQL
    result = query(sql, limit, offset)
    return [] if result.ntuples == 0

    result.map do |tuple|
      tuple_to_hash_for_post(tuple)
    end
  end

  def num_posts
    sql = <<~SQL
      SELECT COUNT(id) AS "num_posts" 
        FROM posts;
    SQL
    result = query(sql)
    result.first['num_posts'].to_i || 0
  end

  def find_post(post_id, limit=nil, offset=nil)
    sql = <<~SQL
      SELECT p.*, u.username
        FROM posts p
        INNER JOIN users u ON p.author_id = u.id
        WHERE p.id = $1
    SQL
    result = query(sql, post_id)
    return if result.ntuples == 0

    post_hash = tuple_to_hash_for_post(result.first)
    post_hash[:comments] = find_post_comments(post_id, limit, offset)
    post_hash
  end

  def add_post(title, content, author_id)
    sql = <<~SQL
      INSERT INTO posts (title, content, author_id)
        VALUES ($1, $2, $3)
    SQL
    query(sql, title, content, author_id)
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

  def delete_post(post_id)
    sql = "DELETE FROM posts WHERE id = $1"
    query(sql, post_id)
  end

  def num_comments(post_id)
    sql = <<~SQL
      SELECT COUNT(id) AS "num_comments"
        FROM comments
        WHERE post_id = $1
    SQL
    result = query(sql, post_id)
    result.first['num_comments'].to_i || 0
  end

  def find_comment(comment_id)
    sql = <<~SQL
      SELECT c.*, u.username
        FROM comments c
        INNER JOIN users u ON c.author_id = u.id
        WHERE c.id = $1
    SQL
    result = query(sql, comment_id)
    return if result.ntuples == 0

    tuple_to_hash_for_comment(result.first)
  end

  def add_comment_to_post(post_id, author_id, comment)
    sql = <<~SQL
      INSERT INTO comments (post_id, author_id, content)
        VALUES ($1, $2, $3)
    SQL
    query(sql, post_id, author_id, comment)
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

  def delete_comment(comment_id)
    sql = "DELETE FROM comments WHERE id = $1"
    query(sql, comment_id)
  end
  
  def find_user(username)
    sql = <<~SQL
      SELECT *
        FROM users
        WHERE username ILIKE $1
    SQL
    result = query(sql, username)
    return {} if result.ntuples == 0

    tuple = result.first
    { id: tuple['id'].to_i,
      username: tuple['username'],
      password: tuple['password']
    }
  end

  def add_user(username, password)
    sql = <<~SQL
      INSERT INTO users (username, password)
        VALUES ($1, $2)
    SQL
    @db.exec_params(sql, [username, password]) # do not log sensitive info
  end

  def username_exists?(username)
    sql = "SELECT id FROM users WHERE username ILIKE $1"
    result = query(sql, username)
    result.ntuples > 0
  end

  private

  def find_post_comments(post_id, limit, offset)
    sql = <<~SQL
      SELECT c.*, u.username 
        FROM comments c
        INNER JOIN users u ON c.author_id = u.id
        WHERE post_id = $1
        ORDER BY update_date DESC, c.id DESC
        LIMIT $2 OFFSET $3
    SQL
    result = query(sql, post_id, limit, offset)
    return [] if result.ntuples == 0

    result.map do |tuple|
      tuple_to_hash_for_comment(tuple)
    end
  end

  def tuple_to_hash_for_post(tuple)
    { id: tuple['id'].to_i,
      title: tuple['title'],
      content: tuple['content'],
      date: tuple['creation_date'],
      update_date: tuple['update_date'],
      author_id: tuple['author_id'].to_i,
      author: tuple['username'],
    }
  end

  def tuple_to_hash_for_comment(tuple)
    { id: tuple['id'].to_i,
      content: tuple['content'],
      date: tuple['creation_date'],
      update_date: tuple['update_date'],
      author_id: tuple['author_id'].to_i,
      author: tuple['username'],
      post_id: tuple['post_id'].to_i 
    }
  end
end
