require 'httparty'
require 'nokogiri'
require 'wicked_pdf'
require 'csv'

# scraper przypjmuje link do wyniku wyszukiwania ofert w serwisie otomoto,
# tworzy plik csv z danymi pojazdów oraz plik pdf zawierający zdjęcia i dane znalezionych pojazdów
class Scraper
  # link zawiera link do wyniku wyszukiwania ofert przez otomoto
  # dane zawierają informacje o nazwie pojazdu, przebiegu, paliwie, skrzyni biegów, roku produkcji i cenie
  # zdjecia zawiera linki do zdjęć samochodów z wyniku wyszukiwania
  attr_accessor :link, :dane, :zdjecia

  def initialize(link)
    @link = link
  end

  # Metoda pobierająca zawartość strony za pomocą Nokogiri i HTTParty
  def get_doc
    response = HTTParty.get(@link)
    html = response.body
    Nokogiri::HTML(html)
  end

  # Metoda, która na podstawie XPath znajduje szukane informacje o znalezionych samochodach
  # i przekazuje je do pola @dane, a linki do zdjęć przekazuje do pola @zdjecia
  def get_data
    doc = get_doc

    nazwa_samochodu = doc.xpath("//article//section//div[2]//h1//a")
    zdjecia = doc.xpath("//article//section//div[1]//img")
    cena = doc.xpath("//article//section//div[4]//div[2]//div[1]//h3")
    przebieg = doc.xpath("//article//section//div[3]//dl[1]//dd[1]")
    paliwo = doc.xpath("//article//section//div[3]//dl[1]//dd[2]")
    skrzynia_biegow = doc.xpath("//article//section//div[3]//dl[1]//dd[3]")
    rok_produkcji = doc.xpath("//article//section//div[3]//dl[1]//dd[4]")

    linki = []
    zdjecia.each do |z|
      linki.push(z['src'])
    end

    @zdjecia = linki
    @dane = nazwa_samochodu.zip(przebieg, paliwo, skrzynia_biegow, rok_produkcji, cena)

  end

  # Metoda zapisująca pobrane dane do pliku csv
  def create_csv
    CSV.open('samochody.csv', 'wb') do |csv|
      @dane.each do |samochod|
        nazwa, przebieg, paliwo, skrzynia, rok, cena = samochod
        csv << [nazwa.text, przebieg.text, paliwo.text, skrzynia.text, rok.text, cena.text]
      end
    end
  end

  # Metoda generująca plik PDF na podstawie pobranych danych
  def create_pdf

    # Styl umieszcza zdjęcie i dane pojazdu w dwóch kontenerach znajdujących się obok siebie
    pdf_content = "<html>
                   <head>
                      <meta charset='utf-8'>
                      <style>
                        .container {
                          display: flex;
                          justify-content: space-between;
                        }
                        .box {
                          width: 50%;
                          padding: 10px;
                        }
                        img {
                          width: 400px;
                          height: 400px;
                        }
                      </style>
                   </head>
                   <body>"

      # Pętla dodaje kolejne elementy <div> zawierające zdjęcie i dane pojazdu
      @dane.each_with_index do |samochod, index|
        nazwa, przebieg, paliwo, skrzynia, rok, cena = samochod
        zdjecie = @zdjecia[index]

        pdf_content += "<div class='container'>"
        pdf_content += "<div class='box'>"
        pdf_content += "<img src='#{zdjecie}' alt='Car Photo'>"
        pdf_content += "</div>"
        pdf_content += "<div class='box'>"
        pdf_content += "<p>Nazwa: #{nazwa.text}</p>"
        pdf_content += "<p>Przebieg: #{przebieg.text}</p>"
        pdf_content += "<p>Paliwo: #{paliwo.text}</p>"
        pdf_content += "<p>Skrzynia biegów: #{skrzynia.text}</p>"
        pdf_content += "<p>Rok produkcji: #{rok.text}</p>"
        pdf_content += "<p>Cena: #{cena.text} PLN</p>"
        pdf_content += "</div>"
        pdf_content += "</div>"
      end
    pdf_content += "</body>
                    </html>"

    # Utworzenie i zapisanie pliku pdf poprzez wykorzystanie wicked_pdf
    pdf = WickedPdf.new.pdf_from_string(pdf_content)
    File.open('samochody.pdf', 'wb') do |file|
      file << pdf
    end

  end

  # Metoda wypisuje do konsoli wszystkie dane zapisane do pliku csv i linki do zdjęć
  def print_data_to_console
    @dane.each do |samochod|
      nazwa, przebieg, paliwo, skrzynia, rok, cena = samochod
      puts "Nazwa: #{nazwa.text}, Przebieg: #{przebieg.text}, Paliwo: #{paliwo.text}, Skrzynia biegów: #{skrzynia.text}, Rok produkcji: #{rok.text}, Cena: #{cena.text} PLN"
    end

    @zdjecia.each do |z|
      puts "Url zdjęcia: #{z}"
    end

  end

  # Metoda pobierająca tekst w formacie json z danymi samochodów z wyniku wyszukiwania
  def get_json(doc)
    script_tag = doc.at('script#listing-json-ld')

    # Sprawdzenie, czy znaleziono znacznik <script>
    if script_tag
      # Wyodrębnienie tekstu z tagu <script>
      script_content = script_tag.inner_text

      # Wyodrębnienie danych JSON z tekstu
      json_data = JSON.parse(script_content)

      # Nazwa pliku do zapisu
      json_filename = 'otomoto_data.json'

      # Zapisanie danych JSON do pliku
      File.open(json_filename, 'w') { |file| file.write(JSON.pretty_generate(json_data)) }

      puts "Dane JSON zostały zapisane do pliku #{json_filename}."
    else
      puts "Nie znaleziono znacznika <script> zawierającego dane JSON."
    end
  end

end

# Podany link jest odnośnikiem do wyniku wyszukiwania w serwisie otomoto
otomoto_link = 'https://www.otomoto.pl/osobowe/bmw/seg-sedan/od-2004?search%5Bfilter_float_price%3Ato%5D=10000&search%5Bfilter_float_year%3Ato%5D=2008'

scraper = Scraper.new(otomoto_link)
scraper.get_data
#scraper.print_data_to_console
scraper.create_csv
scraper.create_pdf
