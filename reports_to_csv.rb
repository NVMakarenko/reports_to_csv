require 'json'
require 'csv'

# Path to the reports
reports_folder = 'reports'

# Output CSV-file
output_csv_base = 'unlighthouse_data_extended'

# Constraint. Notes: Google Docs has it's constraints for files sizing
MAX_CELLS = 25_000
MAX_FILE_SIZE_MB = 80
BYTES_PER_MB = 1_048_576

# Array for data
extracted_data = []

# Searching JSON-files in a folder
Dir.glob("#{reports_folder}/**/*.json").each do |file_path|
  begin
    # Parse JSON
    report = JSON.parse(File.read(file_path))

    # Getting data from report.
    ### Write down here parameters you need to analyse
    data_row = {
      lighthouse_version: report['lighthouseVersion'],
      fetch_time: report['fetchTime'],
      requested_url: report['requestedUrl'],
      report_link: file_path,
    # Scores
      performance_score: report.dig('categories', 'performance', 'score'),
      accessibility_score: report.dig('categories', 'accessibility', 'score'),
      best_practices_score: report.dig('categories', 'best-practices', 'score'),
      seo_score: report.dig('categories', 'seo', 'score'),
    # Performance data
      first_contentful_paint: report.dig('audits', 'first-contentful-paint', 'displayValue'),
      largest_contentful_paint: report.dig('audits', 'largest-contentful-paint', 'displayValue'),
      cumulative_layout_shift: report.dig('audits', 'cumulative-layout-shift', 'displayValue'),
      speed_index: report.dig('audits', 'speed-index', 'displayValue'),
    # Accessibility
      contrast_issues: report.dig('audits', 'color-contrast', 'details', 'items')&.length,
      missing_alt_text: report.dig('audits', 'image-alt', 'details', 'items')&.length,
    # Best Practices
      best_practices_image_responsive: report.dig('audits', 'image-responsive', 'score'),
    # SEO
      seo_description: report.dig('audits', 'meta-description', 'details', 'description'),
      seo_share_image: report.dig('audits', 'structured-data', 'details', 'shareImage'),
    }

    # Add row to data
    extracted_data << data_row
  rescue JSON::ParserError => e
    puts "Error reading JSON file: #{file_path}"
    puts e.message
  end
end

# Save data to CSV
def save_to_csv(data, base_name, file_index)
  headers = data.first.keys
  file_name = "#{base_name}_#{file_index}.csv"
  CSV.open(file_name, 'w', write_headers: true, headers: headers) do |csv|
    data.each { |row| csv << row }
  end
  puts "CSV file is created: #{file_name}"
end

# If csv too big, write it in separate files
if extracted_data.any?
  file_index = 1
  current_data = []
  current_cells = 0

  extracted_data.each do |row|
    # Add row
    current_data << row
    current_cells += row.keys.size

    # Check limits
    if current_cells >= MAX_CELLS
      save_to_csv(current_data, output_csv_base, file_index)
      file_index += 1
      current_data = []
      current_cells = 0
    end
  end

  unless current_data.empty?
    save_to_csv(current_data, output_csv_base, file_index)
  end
else
  puts 'No JSON-file or it is empty.'
end
