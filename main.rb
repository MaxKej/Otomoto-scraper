require_relative 'scraper.rb'

# Podane linki są odnośnikami do wyników wyszukiwania w serwisie otomoto
otomoto_link_1 = 'https://www.otomoto.pl/osobowe/bmw/seg-sedan/od-2004?search%5Bfilter_float_price%3Ato%5D=10000&search%5Bfilter_float_year%3Ato%5D=2008'
otomoto_link_2 = 'https://www.otomoto.pl/osobowe/ford/seg-sedan/od-2005?search%5Bfilter_float_price%3Ato%5D=10000&search%5Bfilter_float_year%3Ato%5D=2010'

scraper = Scraper.new('')
scraper.file_path = "Test_files/output_2.html"
scraper.get_doc
scraper.get_data
#scraper.print_data_to_console
scraper.create_csv
scraper.create_pdf