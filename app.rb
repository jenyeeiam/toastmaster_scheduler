require "sinatra"
require 'sinatra/activerecord'
require 'yaml/store'
require 'pg'
require 'pry'
require 'sendgrid-ruby'
include SendGrid
require 'dotenv/load'
require 'active_record'
# set :database_file, 'config/database.yml'
require './environments'

# ActiveRecord::Base.establish_connection(ENV['DATABASE_URL'] || 'postgres://localhost/toasty_development')

current_dir = Dir.pwd
Dir["#{current_dir}/models/*.rb"].each { |file| require file }

class App < Sinatra::Base

  get '/' do
    @header = "Proposed Schedule This Week"
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
    speakers = Member.order(:speaker).limit(3).pluck(:name)
    @roles['speaker_1'] = speakers[0]
    @roles['speaker_2'] = speakers[1]
    @roles['speaker_3'] = speakers[2]

    evaluators_sorted = Member.order(:evaluator).pluck(:name)

    evaluators = evaluators_sorted - @roles.values
    @roles['evaluator_1'] = evaluators[0]
    @roles['evaluator_2'] = evaluators[1]
    @roles['evaluator_3'] = evaluators[2]

    tt_evaluators_sorted = Member.order(:tt_evaluator).pluck(:name)

    tt_evaluators = tt_evaluators_sorted - @roles.values
    @roles['tt_evaluator_1'] = tt_evaluators[0]
    @roles['tt_evaluator_2'] = tt_evaluators[1]

    toastmasters_sorted = Member.order(:toastmaster).pluck(:name)

    toastmasters = toastmasters_sorted - @roles.values
    @roles['toastmaster'] = toastmasters[0]

    chairs_sorted = Member.order(:chair).pluck(:name)

    chairs = chairs_sorted - @roles.values
    @roles['chair'] = chairs[0]

    topics_masters_sorted = Member.order(:topics_master).pluck(:name)

    topics_masters = topics_masters_sorted - @roles.values
    @roles['topics_master'] = topics_masters[0]

    ges_sorted = Member.order(:ge).pluck(:name)

    ges = ges_sorted - @roles.values
    @roles['ge'] = ges[0]

    functionaries_sorted = Member.order(:functionary).pluck(:name)

    functionaries = functionaries_sorted - @roles.values
    @roles['ah_counter'] = functionaries[0]
    @roles['grammarian'] = functionaries[1]
    @roles['timer'] = functionaries[2]

    @members = Member.pluck(:name)

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
    @members = Member.pluck(:name)
    @header = "Revised Schedule This Week"
    erb :index
  end

  get '/mailer' do
    mail = Mail.new
    mail.from = Email.new(email: 'toasty_scheduler@theword.com')
    mail.reply_to = Email.new(email: 'jenyee1022@gmail.com')
    mail.subject = 'Your next schedule'
    @store = YAML::Store.new 'members.yml'
    @roles = @store.transaction { @store['members'] }
    html_content = ''
    @roles.each do |role, member|
      html_content << "<p>#{role.gsub('_', ' ').upcase}: #{member}</p>"
    end
    html_content << "<a href='https://toasty-scheduler.herokuapp.com/revised'>Go to revised schedule</a>"
    mail.add_content(Content.new(type: 'text/html', value: "<html><body>#{html_content}</body></html>"))
    personalization = Personalization.new
    personalization.add_to(Email.new(email: 'jenyee1022@gmail.com', name: 'Jen'))
    mail.add_personalization(personalization)
    sg = SendGrid::API.new(api_key: ENV['SENDGRID_API_KEY'])
    response = sg.client.mail._('send').post(request_body: mail.to_json)
    puts response.status_code
    puts response.body
    puts response.headers
    @members = Member.pluck(:name)
    @header = "Email Successfully Sent!"
    erb :index
  end

  # This should run after the meeting
  post '/schedule' do
    @store = YAML::Store.new 'members.yml'
    @roles = @store.transaction { @store['members'] }
    @freq_store = YAML::Store.new 'role_frequencies.yml'
    @frequencies = @freq_store.transaction { @freq_store['role_frequencies']}

    @roles.each do |role, member|
      unless member == 'Open'
        generic_role = role.gsub(/_\d/, '')
        if role == 'grammarian' || role == 'ah_counter' || role == 'timer'
          generic_role = 'functionary'
        end
        member_role_freqs = Member.select("speaker, evaluator, toastmaster, chair, ge, topics_master, functionary, tt_evaluator").where('name = ?', member).first
        puts member_role_freqs.inspect

        # decrements all the roles
        member_role_freqs.speaker -= 1 if member_role_freqs.speaker != 0
        member_role_freqs.evaluator -= 1 if member_role_freqs.evaluator != 0
        member_role_freqs.toastmaster -= 1 if member_role_freqs.toastmaster != 0
        member_role_freqs.chair -= 1 if member_role_freqs.chair != 0
        member_role_freqs.ge -= 1 if member_role_freqs.ge != 0
        member_role_freqs.topics_master -= 1 if member_role_freqs.topics_master != 0
        member_role_freqs.functionary -= 1 if member_role_freqs.functionary != 0
        member_role_freqs.tt_evaluator -= 1 if member_role_freqs.tt_evaluator != 0
        # This resets the counter for the role fullfilled this week
        member_role_freqs[generic_role] = @frequencies[role]
        member_role_freqs.save
        puts member_role_freqs.inspect
      end
    end
    redirect '/revised'
  end
end
