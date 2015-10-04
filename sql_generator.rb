class SqlBuilder
  def self.select(table: '', cols: '*', where: '', group: '', order: '', extra: '')
    sql = "select #{cols}"
    sql << " from #{table}" unless table.empty?
    sql << " where #{where}" unless where.empty?
    sql << " group by #{group}" unless group.empty?
    sql << " order by #{order}" unless order.empty?
    sql << " #{extra}" unless extra.empty?
    sql << ';'
  end

  def self.insert(table, cols: '', values: '', query: '')
    sql = "insert into #{table}"
    sql << "(#{cols})" unless cols.empty?
    sql << " values (#{values})" unless values.empty?
    sql << " #{query}" unless query.empty?
    sql << ';'
  end

  def self.update(table, cols, from: '', where: '')
    sql = "update #{table} set #{cols}"
    sql << " from #{from}" unless from.empty?
    sql << " where #{where}" unless where.empty?
    sql << ';'
  end

  def self.drop(name, element, if_exists: false, cascade: false)
    sql = "drop #{element} "
    sql << " if exists " if if_exists
    sql << name
    sql << " cascade" if cascade
    sql << ';'
  end

  def self.create(name, element, extra, if_not_exists: false)
    sql = "create #{element} "
    sql << " if not exists " if if_not_exists
    sql << "#{name} #{extra};"
  end

  def self.create_table(name, cols, if_not_exists: false)
    create(name, 'table', "(#{cols})")
  end

  def self.alter(name, element, extra)
    sql = "alter #{element} #{name} #{extra};"
  end

  def self.prep_values(cols)
    values = ''
    cols.split(/,/).each_with_index { |v, i| values << "$#{i + 1}, " }
    values[0..-3]
  end
end
