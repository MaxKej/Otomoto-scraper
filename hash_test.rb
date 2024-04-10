require_relative 'scraper.rb'
require 'minitest/autorun'

class ScraperTest < MiniTest::Test
  def capture_console_output(&block)
    output = StringIO.new
    $stdout = output
    yield
    $stdout = STDOUT
    output.string
  end


  def test_html_content

    # First instance
    instance1_output = capture_console_output do
    instance1 = Scraper.new('')
    instance1.file_path = "Test_files/output_1.html"
    instance1.get_doc
    instance1.get_data
    instance1.print_data_to_console
    end

    # Second instance
    instance2_output = capture_console_output do
    instance2 = Scraper.new('')
    instance2.file_path = "Test_files/output_1.html"
    instance2.get_doc
    instance2.get_data
    instance2.print_data_to_console
    end

    # Third instance
    instance3_output = capture_console_output do
    instance3 = Scraper.new('')
    instance3.file_path = "Test_files/output_2.html"
    instance3.get_doc
    instance3.get_data
    instance3.print_data_to_console
    end

    assert_equal instance1_output, instance2_output, "Console outputs for instance1 and instance2 are not equal"
    refute_equal instance1_output, instance3_output, "Console outputs for instance1 and instance3 are equal"
  end
end
