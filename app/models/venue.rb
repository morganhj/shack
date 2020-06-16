class Venue < ApplicationRecord
  CATEGORIES = ["All Categories", "Private House", "Outdoor", "Castle"]
  ACTIVITIES = ["All Activities", "Wedding", "Dinner", "Work"]
  PERKS = ["Internet", "Parking", "Air Conditioning", "Heating", "Security", "Kitchen", "Catering", "Handycap Friendly"]
  geocoded_by :location
  belongs_to :user
  has_many :bookings, dependent: :nullify
  has_many :reviews, through: :bookings
  has_many_attached :photos
  monetize :price_cents

  validates :name, presence: :true
  validates :category, presence: :true
  validates :activity, presence: :true
  validates :location, presence: :true
  validates :description, presence: :true
  validates :capacity, presence: :true
  validates :price, presence: :true

  after_validation :geocode, if: :will_save_change_to_location?

  def average_rating
    sum = 0

    self.reviews.each do |review|
      sum += review.rating
    end

    if self.reviews.length == 0
      ""
    else
      sum.fdiv(self.reviews.length)
    end
  end

  def unavailable_dates

      bookings.pluck(:start_date, :end_date).map do |range|
        { from: range[0], to: range[1] }

    end
  end

  def venue_image
    if self.photos.attached?
      self.photos.first.key
    else
      "defaultEventImage"
    end
  end

  def self.perk_icon(perk)
    case perk
      when "Internet"
        string = 'wifi'
      when "Parking"
        string = 'parking'
      when "Air Conditioning"
        string = 'wind'
      when "Heating"
        string = 'fire'
      when "Security"
        string = 'user-shield'
      when "Kitchen"
        string = 'utensils'
      when "Catering"
        string = 'cheese'
      else
        string = 'question'
      end
      return string
  end

  def perks_array
    self.perks.nil? ? array = [] : array = self.perks.split(", ")
    return array
  end

  def is_in_mapbox(bounds)
    lng = self.longitude > bounds[:sw_lng] && self.longitude < bounds[:ne_lng]
    lat = self.latitude > bounds[:sw_lat] && self.latitude < bounds[:ne_lat]
    return lng && lat
  end

  def upcoming_checkin_date
    answer = ''
    bookings = self.bookings.where(status: "approved")
    if bookings.empty?
      answer = {string: 'none', date: 'none', booking: 'none'}
    else
      answer = {string: bookings.order(start_date: :asc).first.start_date.strftime("%B %d, %Y at %H:%M"),
      date: bookings.order(start_date: :asc).first.start_date,
      booking: bookings.order(start_date: :asc).first }
    end
    return answer
  end

  def upcoming_checkout_date
    answer = ''
    bookings = self.bookings.where(status: "ongoing")
    if bookings.empty?
      answer = {string: 'none', date: 'none', booking: 'none'}
    else
      answer = {string: bookings.order(end_date: :asc).first.end_date.strftime("%B %d, %Y at %H:%M"),
      date: bookings.order(end_date: :asc).first.end_date,
      booking: bookings.order(end_date: :asc).first }
    end
    return answer
  end

  def number_of_approved_bookings
    answer = ''
    if self.bookings.where(status: "approved").empty?
      answer = 'none'
    else
      answer = self.bookings.where(status: "approved").count
    end
    return answer
  end

end
