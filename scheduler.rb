require 'sinatra'
require 'yaml/store'
require 'pg'
require 'pry'
require 'sendgrid-ruby'
include SendGrid
require 'dotenv/load'

con = PG.connect :dbname => 'toastmasters', :user => 'jennifer'

role_frequencies = {
  'speaker_1' => 6,
  'speaker_2' => 6,
  'speaker_3' => 6,
  'evaluator_1' => 6,
  'evaluator_2' => 6,
  'evaluator_3' => 6,
  'tt_evaluator_1' => 8,
  'tt_evaluator_2' => 8,
  'toastmaster' => 4,
  'chair' => 4,
  'topics_master' => 4,
  'ge' => 4,
  'grammarian' => 4,
  'ah_counter' => 4,
  'timer' => 4
}

get '/' do
  @roles = {
    'speaker_1' => '',
    'speaker_2' => '',
    'speaker_3' => '',
    'evaluator_1' => '',
    'evaluator_2' => '',
    'evaluator_3' => '',
    'tt_evaluator_1' => '',
    'tt_evaluator_2' => '',
    'toastmaster' => '',
    'chair' => '',
    'topics_master' => '',
    'ge' => '',
    'grammarian' => '',
    'ah_counter' => '',
    'timer' => ''
  }
  speakers = con.exec("select name from members order by speaker asc").values.map{|m| m.first}
  @roles['speaker_1'] = speakers[0]
  @roles['speaker_2'] = speakers[1]
  @roles['speaker_3'] = speakers[2]

  evaluators_sorted = con.exec("select name from members order by evaluator asc").values.map{|m| m.first}

  evaluators = evaluators_sorted - @roles.values
  @roles['evaluator_1'] = evaluators[0]
  @roles['evaluator_2'] = evaluators[1]
  @roles['evaluator_3'] = evaluators[2]

  tt_evaluators_sorted = con.exec("select name from members order by tt_evaluator asc").values.map{|m| m.first}

  tt_evaluators = tt_evaluators_sorted - @roles.values
  @roles['tt_evaluator_1'] = tt_evaluators[0]
  @roles['tt_evaluator_2'] = tt_evaluators[1]

  toastmasters_sorted = con.exec("select name from members order by toastmaster asc").values.map{|m| m.first}

  toastmasters = toastmasters_sorted - @roles.values
  @roles['toastmaster'] = toastmasters[0]

  chairs_sorted = con.exec("select name from members order by chair asc").values.map{|m| m.first}

  chairs = chairs_sorted - @roles.values
  @roles['chair'] = chairs[0]

  topics_masters_sorted = con.exec("select name from members order by topics_master asc").values.map{|m| m.first}

  topics_masters = topics_masters_sorted - @roles.values
  @roles['topics_master'] = topics_masters[0]

  ges_sorted = con.exec("select name from members order by ge asc").values.map{|m| m.first}

  ges = ges_sorted - @roles.values
  @roles['ge'] = ges[0]

  functionaries_sorted = con.exec("select name from members order by functionary asc").values.map{|m| m.first}

  functionaries = functionaries_sorted - @roles.values
  @roles['ah_counter'] = functionaries[0]
  @roles['grammarian'] = functionaries[1]
  @roles['timer'] = functionaries[2]

  @members = con.exec("select name from members").values.map{|m| m.first}

  @store = YAML::Store.new 'members.yml'
  @store.transaction do
    @roles.each do |role, name|
      @store['members'] ||= {}
      @store['members'][role] = name
    end
  end
  erb :index
end

post '/roles' do
  @store = YAML::Store.new 'members.yml'
  @member = @store.transaction { @store['members'][params[:roles_list]] = params[:member_list] }
  redirect '/revised'
end

get '/revised' do
  @store = YAML::Store.new 'members.yml'
  @roles = @store.transaction { @store['members'] }
  @members = con.exec("select name from members").values.map{|m| m.first}
  erb :index
end

get '/mailer' do
  mail = Mail.new
  mail.from = Email.new(email: 'jenyee1022@gmail.com')
  mail.reply_to = Email.new(email: 'jenyee1022@gmail.com')
  mail.subject = 'Your next schedule'
  @store = YAML::Store.new 'members.yml'
  @roles = @store.transaction { @store['members'] }
  html_content = ''
  @roles.each do |role, member|
    html_content << "<p>#{role.gsub('_', ' ').upcase}: #{member}</p>"
  end
  mail.add_content(Content.new(type: 'text/html', value: "<html><body>#{html_content}</body></html>"))
  personalization = Personalization.new
  personalization.add_to(Email.new(email: 'jenyee1022@gmail.com', name: 'Jen'))
  mail.add_personalization(personalization)
  sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
  response = sg.client.mail._('send').post(request_body: mail.to_json)
  puts response.status_code
  puts response.body
  puts response.headers
  @members = con.exec("select name from members").values.map{|m| m.first}
  @header = "Thanks for Playing"
  erb :index
end

# This should run after the meeting
post '/schedule' do
  @store = YAML::Store.new 'members.yml'
  @roles = @store.transaction { @store['members'] }
  @roles.each do |role, member|
    unless member == 'Open'
      generic_role = role.gsub(/_\d/, '')
      if role == 'grammarian' || role == 'ah_counter' || role == 'timer'
        generic_role = 'functionary'
      end
      con.exec("UPDATE members SET #{generic_role} = #{role_frequencies[role]} WHERE name = '#{member}'")
    end
  end
  redirect '/'
end