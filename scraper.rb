# frozen_string_literal: true

require 'pry'
require 'require_all'
require 'scraped'
require 'scraperwiki'
require 'json'

# require_rel 'lib'

def scrape(h)
  url, klass = h.to_a.first
  klass.new(response: Scraped::Request.new(url: url).response)
end

module Scraped
  class JSON < Document
    private

    def initialize(json: nil, **args)
      super(**args)
      @json = json
    end

    def json
      @json ||= ::JSON.parse(response.body, symbolize_names: true)
    end

    def fragment(mapping)
      json_fragment, klass = mapping.to_a.first
      klass.new(json: json_fragment, response: response)
    end
  end
end

class MapitArea < Scraped::JSON
  field :id do
    json[:id]
  end

  field :name do
    json[:name]
  end

  field :osm_rel do
    json[:codes][:osm_rel]
  end
end

class MapitAreas < Scraped::JSON
  field :areas do
    json.values.map { |area| fragment(area => MapitArea) }.map(&:to_h)
  end
end

areas = scrape('http://global.mapit.mysociety.org/areas/OCL' => MapitAreas).to_h[:areas]

ScraperWiki.sqliteexecute('DROP TABLE data') rescue nil
ScraperWiki.save_sqlite([:id], areas)
