class LessondescPattern < ActiveRecord::Base
  belongs_to :lesson, :foreign_key => :lessonid
  belongs_to :language, :foreign_key => :lang, :primary_key => :code3
  attr_accessible :pattern, :description, :lang

  validates :pattern, :presence => true, :uniqueness => {:scope => :lang}
  validates :lang, :description, :presence => true

  scope :pattern_matches, lambda{ |string|
    where("'#{string}' regexp pattern")
  }

  # ThinkingSphinx.search
  define_index do
    indexes pattern, :sortable => true
    indexes description, :sortable => true

    set_property :delta => true
  end

end
