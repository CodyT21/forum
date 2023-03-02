require 'pg'

module DatabaseConnection
  def initialize(logger=nil)
    @db = if ENV['RACK_ENV'] == 'test'
            PG.connect(dbname: 'forum_test')
          else
            PG.connect(dbname: 'forum')
          end
    @logger = logger
    setup_schema
  end
  
  def query(statement, *params)
    @logger.info("#{statement}: #{params}") if @logger
    @db.exec_params(statement, params)
  end

  def clear
    @db.exec("DELETE FROM posts;")
    @db.exec("ALTER SEQUENCE posts_id_seq RESTART WITH 1;")
    @db.exec("DELETE FROM comments;")
    @db.exec("ALTER SEQUENCE comments_id_seq RESTART WITH 1;")
    @db.exec("DELETE FROM users;")
    @db.exec("ALTER SEQUENCE users_id_seq RESTART WITH 1;")
  end

  private

  def setup_schema
    result = @db.exec <<~SQL
      SELECT COUNT(*) FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'posts';
    SQL

    if result.first['count'] == '0'
      commands = File.read('./schema.sql').gsub("\n", '').split(';')
      commands.each { |command| @db.exec(command) }
    end
  end
end