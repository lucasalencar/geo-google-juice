require_relative "db"
require_relative "thread_pool"

def log(msg)
  puts "#{Time.now}: #{msg}"
end

class GoogleJuice
  LON_CORRECTION = 0.00555582517718278
  LAT_CORRECTION = 0.00195860504566525

  def initialize(db_name, table, gtable, api_key)
    @db = DB.new(db_name)
    @db_name = db_name
    @table = table
    @gtable = gtable

    @gclient = GooglePlaces::Client.new(api_key)
    init_db
  end

  def init_db
    @db.drop(@gtable, 'table', if_exists: true, cascade: true)
    cols = 'gid serial, building_gid numeric, corrected_lon numeric, corrected_lat numeric, lon numeric, lat numeric, name text, type text'
    @db.create_table(@gtable, cols, if_not_exists: true)
  end

  def load_google_places(radius, exclude, extra: '', gid: nil)
    cols = 'gid, ST_AsText(ST_Centroid(the_geom)) as point'
    where = ''; where = "gid = #{gid}" unless gid.nil?
    @db.select(table: @table, cols: cols, order: 'gid', extra: extra, where: where).each do |rpoints|
      gid = rpoints['gid']; point = rpoints['point']
      load_gplace(gid, point, radius, exclude)
    end
  end

  def load_gplace(gid, point, radius, exclude)
    log "Processing gid #{gid}"
    point_syntax = /POINT\((\d+.\d+) (\d+.\d+)\)/
    begin
      if point_syntax =~ point
        lon, lat = correct_coord($1, $2)
        rows = fetch_gplaces(gid, lon, lat, radius, exclude)
        # log "Running queries for #{gid}"
        save_gplaces(gid, rows)
      end
    rescue
      log "Problem when retrieving gid #{gid}."
      File.open('problems.txt', 'a') do |f|
        f << "#{gid}\n"
      end
    end
  end

  def fetch_gplaces(gid, lon, lat, radius, exclude)
    @gclient.spots(lat, lon, radius: radius, language: 'en', exclude: exclude).map do |place|
      [gid, lon, lat, place.lng, place.lat, place.name, place.types.first]
    end
  end

  def save_gplaces(gid, rows)
    cols = 'building_gid, corrected_lon, corrected_lat, lon, lat, name, type'
    values = SqlBuilder.prep_values(cols)

    gdb = DB.new(@db_name)
    gdb.prepared_st(SqlBuilder.insert(@gtable, cols: cols, values: values), rows, "insert_gid_#{gid}")
    gdb.close
  end

  def correct_coord(lon, lat)
    return lon.to_f + LON_CORRECTION, lat.to_f + LAT_CORRECTION
  end

  def distances
    @db.alter(@gtable, 'table', 'add column original_dist numeric')
    b = 'st_setsrid(st_point(corrected_lon, corrected_lat), 4326)'
    g = 'st_setsrid(st_point(lon, lat), 4326)'
    cols = "original_dist = st_distance(#{b}, #{g})"
    @db.update(@gtable, cols)
  end

  def update_new_types
    @db.execute("create index on #{@gtable}(building_gid);")
    @db.execute("create index on #{@gtable}(gid);")
    @db.execute("create index on #{@gtable}(original_dist);")

    min_dist = SqlBuilder.select(table: @gtable, cols: 'building_gid, min(original_dist)', group: '1')[0..-2]
    min_dist_join = "#{@gtable} g inner join (#{min_dist}) t on (g.building_gid = t.building_gid and g.original_dist = t.min)"
    min_dist_join_query = SqlBuilder.select(table: min_dist_join, cols: 'g.*')[0..-2]

    # gtype column
    @db.alter(@table, 'table', 'drop column gtype')
    @db.alter(@table, 'table', 'add column gtype text')

    # gtype_gid column
    @db.alter(@table, 'table', 'drop column gtype_gid')
    @db.alter(@table, 'table', 'add column gtype_gid text')

    @db.update("#{@table} b", 'gtype = g.type, gtype_gid = g.gid', from: "(#{min_dist_join_query}) g", where: 'g.building_gid = b.gid')
  end
end
