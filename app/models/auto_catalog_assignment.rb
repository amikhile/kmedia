class AutoCatalogAssignment < ActiveRecord::Base

  def self.match_catalog(lesson)
    @lesson_part_arrival = DateTime.now.in_time_zone 'Jerusalem'
    log_lesson_arrival(lesson)
    return unless lesson_of_interest(lesson)


    load_record
    case @record.counter
      when -1
        match_preparation_part(lesson)
      when 0
        match_part(lesson, 'lesson_first-part')
      when 1
        match_part(lesson, 'lesson_second-part')
      when 2
        match_part(lesson, 'lesson_third-part')
      when 3
        match_part(lesson, 'lesson_fourth-part')
      when 4
        match_part(lesson, 'lesson_fifth-part')
    end

    log_results(lesson)
  end

  def self.lesson_of_interest(lesson)
    today_lesson = @lesson_part_arrival.to_date == lesson.lessondate
    my_logger.info("Today's lesson = #{today_lesson}")
    lesson_of_interest = lesson.content_type.try(:name).eql?("Lesson") && in_time_frame('02:55am', '06:50am') && today_lesson
    my_logger.info("Lesson of interest = #{lesson_of_interest}")
    lesson_of_interest
  end


  def self.load_record
    @record = AutoCatalogAssignment.first
    unless @record.nil?
      # reset the counter if it is a new day
      if @record.last_date.in_time_zone('Jerusalem').to_date < @lesson_part_arrival.to_date
        @record.counter = -1
        my_logger.info("New Day began, reset counter")
      end
    else
      # initialize
      @record = AutoCatalogAssignment.new
      @record.last_date = Date.yesterday.to_time.in_time_zone('Jerusalem').to_date
      @record.counter = -1
      my_logger.info("Initializing autoCatalogAssignment record: counter = #{@record.counter}, last date= #{@record.last_date}")
    end
  end


  def self.preparation_time
    in_time_frame('02:55am', '03:30am')
  end

  def self.first_lesson_time
    in_time_frame('03:30am', '06:50am')
  end

  def self.in_time_frame(string_start_time, string_end_time)
    start_time = Time.use_zone('Jerusalem'){ Time.zone.parse(string_start_time) }
    end_time = Time.use_zone('Jerusalem'){ Time.zone.parse(string_end_time) }
    in_time_frame = @lesson_part_arrival.between?(start_time, end_time)
    my_logger.info("In time frame #{string_start_time} till #{string_end_time} = #{in_time_frame}")
    in_time_frame
  end


  def self.update_record
    @record.last_date = @lesson_part_arrival
    @record.counter += 1
    @record.save
    my_logger.info("Record saved, record: counter = #{@record.counter}, last date= #{@record.last_date}")
  end

  def self.match_preparation_part(lesson)
    # The are catalogs that assigned previously from the match in description pattern
    # if the preparation part was matched by the description pattern we will believe it is a preparation part,
    # no matter what time it arrived to the server
    if preparation_time || preparation_part_already_matched(lesson)
      my_logger.info("Matched preparation part")
      catalog = Catalog.find_by_catalognodename('lesson_preparation')
      lesson.catalogs << catalog unless lesson.catalogs.include? catalog
      update_record
    elsif first_lesson_time
      my_logger.info("Matched first part, there were no preparation part today")
      # there were no preparation part today and it's time for first lesson part
      @record.counter=0
      match_part(lesson, 'lesson_first-part')
    end
  end

  def self.match_part(lesson, catalog_name)
    my_logger.info("Assigning lesson to catalog #{catalog_name}")
    catalog = Catalog.find_by_catalognodename(catalog_name)
    lesson.catalogs << catalog unless lesson.catalogs.include? catalog
    update_record
  end

  def self.my_logger
    @@my_logger ||= Logger.new("#{Rails.root}/log/autoCatalogAssignment.log")
  end

  def self.log_lesson_arrival(lesson)
    #my_logger.info("###############################################################")
    my_logger.info("lesson arrived #{lesson.lessonname} at #{@lesson_part_arrival}")
    my_logger.info("lesson associated to catalogs #{get_catalogs_names(lesson.catalogs)}")
  end

  def self.log_results(lesson)
    my_logger.info("lesson  #{lesson.lessonname} catalog assignment finished. Lesson associated to #{lesson.catalogs.size} catalogs")
    my_logger.info("lesson associated to catalogs #{get_catalogs_names(lesson.catalogs)}")
  end

  def self.get_catalogs_names(catalogs)
    names = []
    catalogs.each{|c|
      names << c.catalognodename
    }
    names.join(",")
  end

  def self.preparation_part_already_matched(lesson)
    lesson.catalogs.include? Catalog.find_by_catalognodename('lesson_preparation')
  end

end
