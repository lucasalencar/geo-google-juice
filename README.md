# Google Juice to your Geo places

Loads google place information to you geo location points.

### Running

```ruby
# Search parameters
EXCLUDE = File.read(EXCLUDED_FILE).split(/\n/)
RADIUS = 50

puts 'Initializing db...'
gj = GoogleJuice.new(db_name, table, gtable, api_key)

puts "Loading google places to database... Using radius = #{RADIUS}."
gj.load_google_places(RADIUS, EXCLUDE)

puts 'Calculating distances between original building and Google data...'
gj.distances

log 'Updating buildings table with Google types closer to the building...'
gj.update_new_types
```
