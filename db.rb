require "pg"
require_relative "sql_generator"

class DB
	def initialize(dbname)
		@conn = PG::Connection.open(dbname: dbname)
	end

  def close
    @conn.close
  end

	def execute(query)
    puts "~> #{query}"
		@conn.exec(query)
	end

  def select(table: '', cols: '*', where: '', group: '', order: '', extra: '')
    execute(SqlBuilder.select(table: table, cols: cols, where: where, group: group, order: order, extra: extra))
  end

  def update(table, cols, from: '', where: '')
    execute(SqlBuilder.update(table, cols, from: from, where: where))
  end

  def insert(table, cols: '', values: '', query: '')
    execute(SqlBuilder.insert(table, cols: cols, values: values, query: query))
  end

  def drop(name, element, if_exists: false, cascade: false)
    execute(SqlBuilder.drop(name, element, if_exists: if_exists, cascade: cascade))
  end

  def create_table(name, cols, if_not_exists: false)
    execute(SqlBuilder.create_table(name, cols, if_not_exists: if_not_exists))
  end

  def alter(name, element, extra)
    execute(SqlBuilder.alter(name, element, extra))
  end

  # row = [uid, date, day_id]
  def prepared_st(model_query, rows, st_name = 'st')
    @conn.prepare(st_name, model_query)
    rows.each do |row|
      @conn.exec_prepared(st_name, row)
    end
    @conn.exec("DEALLOCATE #{st_name}")
  end
end
