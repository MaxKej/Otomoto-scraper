require_relative 'scraper.rb'
require 'fileutils'
require 'rspec'

RSpec.describe Scraper do
  let(:link) { 'https://www.otomoto.pl/osobowe/ford/seg-sedan/od-2005?search%5Bfilter_float_price%3Ato%5D=10000&search%5Bfilter_float_year%3Ato%5D=2010' }
  let(:scraper) { Scraper.new(link) }
  let(:csv_file) { "samochody.csv" }
  let(:pdf_file) { "samochody.pdf" }


  after(:each) do
    FileUtils.rm_rf([csv_file, pdf_file]) # Usuwa pliki po zakończeniu testów
  end

  describe '#create_csv' do
    it 'creates a CSV file' do
      scraper.get_doc
      scraper.get_data
      scraper.create_csv

      expect { scraper.create_csv }.not_to raise_error
      expect(File.exist?(csv_file)).to be true
      expect(File.size?(csv_file)).not_to be nil
    end
  end

  describe '#create_pdf' do
    it 'creates a PDF file' do
      scraper.get_doc
      scraper.get_data
      scraper.create_pdf

      expect { scraper.create_pdf }.not_to raise_error
      expect(File.exist?(pdf_file)).to be true
      expect(File.size?(pdf_file)).not_to be nil
    end
  end
end
