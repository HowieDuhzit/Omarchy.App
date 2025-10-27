require "uri"

class Webapp < ApplicationRecord
  # Validations
  validates :name, presence: true, length: { maximum: 100 }
  validates :url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid HTTP/HTTPS URL" }
  validates :icon_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]), message: "must be a valid HTTP/HTTPS URL" }
  validates :category, presence: true, inclusion: { 
    in: %w[communication project_management development design notes google social entertainment games ai_tools finance cloud_storage hosting education news health],
    message: "must be a valid category"
  }

  # Scopes
  scope :by_category, ->(category) { where(category: category) }
  scope :search_by_name, ->(term) { where("name ILIKE ?", "%#{term}%") }
  scope :search_by_category, ->(term) { where("category ILIKE ?", "%#{term}%") }
  scope :ordered_by_name, -> { order(:name) }
  scope :ordered_by_created, -> { order(created_at: :desc) }

  # Callbacks
  before_save :normalize_urls
  before_validation :strip_whitespace

  def install_uri
    params = { name: name, url: url, icon: icon_url }

    # Special handling for specific apps
    case name.downcase
    when "hey"
      params[:exec] = "omarchy-webapp-handler-hey %u"
      params[:mimeTypes] = "x-scheme-handler/mailto"
    when "zoom"
      params[:exec] = "omarchy-webapp-handler-zoom %u"
      params[:mimeTypes] = "x-scheme-handler/zoommtg;x-scheme-handler/zoomus"
    end

    "omarchy://webappinstall?" + URI.encode_www_form(params)
  end

  def as_api
    { 
      id: id, 
      name: name, 
      url: url, 
      icon: icon_url,
      category: category,
      created_at: created_at.iso8601
    }
  end

  def category_humanized
    category.humanize
  end

  def display_name
    name.truncate(50)
  end

  private

  def normalize_urls
    self.url = normalize_url(url) if url.present?
    self.icon_url = normalize_url(icon_url) if icon_url.present?
  end

  def normalize_url(url_string)
    return url_string if url_string.blank?
    
    # Add protocol if missing
    unless url_string.match?(/\Ahttps?:\/\//)
      url_string = "https://#{url_string}"
    end
    
    url_string
  end

  def strip_whitespace
    self.name = name&.strip
    self.url = url&.strip
    self.icon_url = icon_url&.strip
    self.category = category&.strip&.downcase
  end
end
