require 'spy_glass/registry'

opts = {
  path: '/hawaii-traffic-incidents',
  cache: SpyGlass::Cache::Memory.new(expires_in: 300),
  source: 'http://api.hitraffic.org/v1/incidents?'+Rack::Utils.build_query({
    'limit' => 1000
  })
}

SpyGlass::Registry << SpyGlass::Client::JSON.new(opts) do |collection|
  features = collection.map do |item|
    address = item['address'].split(/\s?&\s?/).join(' & ').titleize
    address = address.gsub(/(?<addy>\d) X/, '\k<addy>X')

    title = <<-TITLE.oneline
      A #{item['type'].downcase} incident has been reported near #{address} in #{item['area'].titleize}.
    TITLE
    if item['geometry']
      {
        'id' => item['_id'],
        'type' => 'Feature',
        'geometry' => {
          'type' => 'Point',
          'coordinates' => [
            item['geometry']['longitude'].to_f,
            item['geometry']['latitude'].to_f
          ]
        },
        'properties' => item.merge('title' => title)
      }
    end
  end

  {'type' => 'FeatureCollection', 'features' => features}
end
