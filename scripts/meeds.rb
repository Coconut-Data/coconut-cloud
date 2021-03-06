require 'rubygems'
require 'couchrest'
require 'mechanize'
require 'json'
require 'net/http'

#RestClient.log = 'stderr'

require_relative 'log_error'

passwords = JSON.parse(IO.read(File.dirname(__FILE__) + "/passwords.json"))

def check_for_new_cases(amount, lastKnownCaseTime)
  page_size = amount
  @agent.get("http://zmcp.selcommobile.com/cases.php?abc_page_size=#{page_size}").search("#abc__contentTable tr").reverse.each_with_index do |row,index|
    columns = row.search("td").map{ |column| column.text }
    next if columns.empty?

    caseNotification = {}
    @columnNames.each_with_index do |columnName,columnIndex|
      caseNotification[columnName] = columns[columnIndex]
    end
    puts "YO"
    puts lastKnownCaseTime
    puts caseNotification
    puts caseNotification["DATE"]
    if caseNotification["DATE"] <= lastKnownCaseTime
      puts "Looking for cases after #{lastKnownCaseTime}, current case is from #{caseNotification["DATE"]}, skipping."
    else
      if index == 0
        puts "More than #{page_size} new cases, trying again with #{2*page_size}"
        check_for_new_cases(2*page_size,lastKnownCaseTime)
        break
      end

      # Check for duplicates in the past 1 hour (60*60) - can't handle more right now.
      duplicate = false
      seconds_to_check = 60 * 60
      #@lastCases ||= @db.view(URI.escape("zanzibar/caseIDsByDate?startkey=\"#{Time.now.strftime("%Y-%m-%d %H:%M:%S")}\"&endkey=\"#{(Time.now - seconds_to_check).strftime("%Y-%m-%d %H:%M:%S")}\"&descending=true&include_docs=true"))['rows']
      #
      @lastCases ||= @db.view("zanzibar/caseIDsByDate", {
        :startkey => Time.now.strftime("%Y-%m-%d %H:%M:%S"),
        :endkey => (Time.now - seconds_to_check).strftime("%Y-%m-%d %H:%M:%S"),
        :descending => true,
        :include_docs => true
      })['rows']
      puts "#{@lastCases.length} cases in the last #{seconds_to_check} seconds"
      @lastCases.each  do |row|
        if row["doc"]["hf"] == caseNotification["FACILITY"] and row["doc"]["name"] == caseNotification["NAME"]
          log_error "Duplicate found: #{caseNotification}"
          duplicate = true
          break
        end
      end

      unless duplicate
        new_case = {:caseid => caseNotification["PAT ID"],:date => caseNotification["DATE"],:hf => caseNotification["FACILITY"].upcase, :name => caseNotification["NAME"].upcase, :shehia => caseNotification["SHEHIA"].upcase, :facility_district => caseNotification["DISTRICT"].upcase, :date_positive => caseNotification["DATE POSITIVE"]}
	if new_case["date_positive"] == "1970-01=01"
	  new_case["date_positive"] == ""
	end
# handling a bug in how one of the facilities is named
        new_case["hf"] = "BEIT-EL-RAAS" if new_case["hf"] == "BEIT-EL -RAAS"
        puts "Creating case: #{new_case.to_json}"
        @db.save_doc(new_case)
      end

    end
  end
end

print "."

@db = (CouchRest.new("https://#{passwords["couchdb_credentials"]}@zanzibar.cococloud.co", :verify_ssl => false)).database("zanzibar")

#lastKnownCaseTime = "2012-10-05 00:00:00" 
begin
lastKnownCaseTime = @db.view('zanzibar/notifications?limit=1&descending=true')['rows'].first["key"]
rescue Exception => e
  puts "ZZZZ"
  puts e
end
puts "lastKnownCaseTime: #{lastKnownCaseTime}"

@agent = Mechanize.new
loginForm = @agent.get('http://zmcp.selcommobile.com/index.php').form
loginForm.username = passwords["username1"]
loginForm.password = passwords["password1"]
@agent.submit(loginForm)

# Note the extra layer of authentication with a slightly different password
loginForm = @agent.get('http://zmcp.selcommobile.com/cases.php').form
loginForm.access_login = passwords["username2"]
loginForm.access_password = passwords["password2"]
@agent.submit(loginForm)

begin
  @columnNames = @agent.get('http://zmcp.selcommobile.com/cases.php?abc_page_size=1').search("#abc__contentTable tr")[0].search("th").map{ |header| header.text.chop}
  check_for_new_cases(1, lastKnownCaseTime)
rescue
  log_error "Problem accessing http://zmcp.selcommobile.com/cases.php - perhaps the site is down or the password has been changed."
end
