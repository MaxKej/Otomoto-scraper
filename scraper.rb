require 'httparty'
require 'nokogiri'
require 'wicked_pdf'
require 'csv'
require 'yard'


# Klasa Scraper służy do scrapowania danych z serwisu Otomoto.
# Przyjmuje link do wyniku wyszukiwania ofert w serwisie otomoto
# i tworzy plik CSV z danymi pojazdów oraz plik PDF zawierający zdjęcia i dane znalezionych pojazdów.
class Scraper
  # Link do wyniku wyszukiwania ofert przez Otomoto.
  # @return [String]
  attr_accessor :link

  # Ścieżka do pliku html w katalogu Output.
  # Plik zawiera kod html z wynikiem wyszukiwania ofert przez Otomoto.
  # @return [String]
  attr_accessor :sciezka

  # Pole ze sparsowanym dokumentem HTML.
  # @return [String]
  attr_accessor :html

  # Dane zawierają informacje o nazwie pojazdu, przebiegu, paliwie, skrzyni biegów, roku produkcji i cenie.
  # Uzyskane metodą zip
  # @return [Array<Array>]
  attr_accessor :dane

  # Zdjęcia zawierają linki do zdjęć samochodów z wyniku wyszukiwania.
  # @return [Array<String>]
  attr_accessor :zdjecia

  # Inicjalizuje nową instancję klasy Scraper.
  #
  # @param link [String] Link do wyniku wyszukiwania ofert przez Otomoto.
  def initialize(link)
    @link = link
  end

  # Metoda pobiera zawartość strony za pomocą HTTParty.
  # Jeśli link jest pusty, metoda pobierze plik wskazany przez zmienną @sciezka
  # Sparsowany dokument HTML zostaje przekazany do zmiennej @html.
  #
  # @return [void]
  def get_doc
    if @link == ''
      file = File.open(@sciezka, "r")
      html_content = file.read
      @html = Nokogiri::HTML(html_content)
      file.close
    else
      response = HTTParty.get(@link)
      html = response.body
      @html = Nokogiri::HTML(html)
      # save_to_html('Test_files/output_2.html', @html)
    end
  end

  # Metoda zapisuje zawartość do pliku HTML.
  #
  # @param filename [String] Nazwa pliku do zapisu.
  # @param content [String] Zawartość do zapisania.
  #
  # @return [void]
  def save_to_html(filename, content)
    File.open(filename, 'w') do |file|
      file.puts(content)
    end
  end


  # Metoda get_data na podstawie XPath znajduje szukane informacje o znalezionych samochodach
  # i przekazuje je do pola @dane, a linki do zdjęć przekazuje do pola @zdjecia
  #
  # @return [void]
  def get_data

    nazwa_samochodu = @html.xpath("//article//section//div[2]//h1//a")
    zdjecia = @html.xpath("//article//section//div[1]//img")
    cena = @html.xpath("//article//section//div[4]//div[2]//div[1]//h3")
    przebieg = @html.xpath("//article//section//div[3]//dl[1]//dd[1]")
    paliwo = @html.xpath("//article//section//div[3]//dl[1]//dd[2]")
    skrzynia_biegow = @html.xpath("//article//section//div[3]//dl[1]//dd[3]")
    rok_produkcji = @html.xpath("//article//section//div[3]//dl[1]//dd[4]")

    linki = []
    zdjecia.each do |z|
      linki.push(z['src'])
    end

    @zdjecia = linki
    @dane = nazwa_samochodu.zip(przebieg, paliwo, skrzynia_biegow, rok_produkcji, cena)

  end

  # Metoda zapisuje pobrane dane do pliku CSV.
  #
  # @return [void]
  def create_csv
    CSV.open('Output/samochody.csv', 'wb') do |csv|
      @dane.each do |samochod|
        nazwa, przebieg, paliwo, skrzynia, rok, cena = samochod
        csv << [nazwa.text, przebieg.text, paliwo.text, skrzynia.text, rok.text, cena.text]
      end
    end
  end


  # Metoda generuje plik PDF na podstawie pobranych danych.
  #
  # @return [void]
  def create_pdf

    # Styl umieszcza zdjęcie i dane pojazdu w dwóch kontenerach znajdujących się obok siebie.
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

    # Pętla dodaje kolejne elementy <div> zawierające zdjęcie i dane pojazdu.
    @dane.each_with_index do |samochod, index|
      nazwa, przebieg, paliwo, skrzynia, rok, cena = samochod
      zdjecie = @zdjecia[index]

      pdf_content += "<div class='container'>"
      pdf_content += "<div class='box'>"
      pdf_content += "<img src='#{zdjecie}' alt='Car Photo'>"
      pdf_content += "</div>"
      pdf_content += "<div class='box'>"
      pdf_content += "<p>Nazwa: #{nazwa}</p>"
      pdf_content += "<p>Przebieg: #{przebieg}</p>"
      pdf_content += "<p>Paliwo: #{paliwo}</p>"
      pdf_content += "<p>Skrzynia biegów: #{skrzynia}</p>"
      pdf_content += "<p>Rok produkcji: #{rok}</p>"
      pdf_content += "<p>Cena: #{cena} PLN</p>"
      pdf_content += "</div>"
      pdf_content += "</div>"
    end
    pdf_content += "</body>
                    </html>"

    # Utworzenie i zapisanie pliku PDF poprzez wykorzystanie wicked_pdf.
    pdf = WickedPdf.new.pdf_from_string(pdf_content)
    File.open('Output/samochody.pdf', 'wb') do |file|
      file << pdf
    end

  end

  # Metoda wypisuje do konsoli wszystkie dane zapisane do pliku csv i linki do zdjęć
  #
  # @return [void]
  def print_data_to_console
    @dane.each do |samochod|
      nazwa, przebieg, paliwo, skrzynia, rok, cena = samochod
      puts "Nazwa: #{nazwa.text}, Przebieg: #{przebieg.text}, Paliwo: #{paliwo.text}, Skrzynia biegów: #{skrzynia.text}, Rok produkcji: #{rok.text}, Cena: #{cena.text} PLN"
    end

    @zdjecia.each do |z|
      puts "Url zdjęcia: #{z}"
    end
  end

  # Metoda pobierająca tekst w formacie JSON z danymi samochodów z wyniku wyszukiwania.
  #
  # @param doc [Nokogiri::HTML::Document] Sparsowany dokument HTML.
  #
  # @return [void]
  def get_json(doc)
    script_tag = doc.at('script#listing-json-ld')

    # Sprawdzenie, czy znaleziono znacznik <script>.
    if script_tag
      # Wyodrębnienie tekstu z tagu <script>.
      script_content = script_tag.inner_text

      # Wyodrębnienie danych JSON z tekstu.
      json_data = JSON.parse(script_content)

      # Nazwa pliku do zapisu.
      json_filename = 'Output/otomoto_data.json'

      # Zapisanie danych JSON do pliku.
      File.open(json_filename, 'w') { |file| file.write(JSON.pretty_generate(json_data)) }

      puts "Dane JSON zostały zapisane do pliku #{json_filename}."
    else
      puts "Nie znaleziono znacznika <script> zawierającego dane JSON."
    end
  end

end
