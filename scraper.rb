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

class MapitArea
  include FieldSerializer

  def initialize(area)
    @area = area
  end

  field :id do
    area[:id]
  end

  field :name do
    area[:name]
  end

  field :osm_rel do
    area[:codes][:osm_rel]
  end

  private

  attr_reader :area
end

class MapitAreas < Scraped::Document
  field :areas do
    json.values.map { |area| MapitArea.new(area) }.map(&:to_h)
  end

  private

  def json
    @json ||= JSON.parse(response.body, symbolize_names: true)
  end
end

areas = scrape('http://global.mapit.mysociety.org/areas/OCL' => MapitAreas).to_h[:areas]

ScraperWiki.sqliteexecute('DROP TABLE data') rescue nil
ScraperWiki.save_sqlite([:id], areas)
