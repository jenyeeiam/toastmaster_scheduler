require 'csv'
require 'pry'

con = PG.connect :dbname => ENV['DATABASE_URL']

desc "Seed the members from csv club roster"
task :seed_members do
  CSV.foreach('lib/tasks/Club-Roster.csv', headers: true) do |row|
    con.exec("INSERT INTO members VALUES (#{row[row.first.first].to_i}, '#{row['Name']}', '#{row['Email']}', #{rand(0..6)}, #{rand(0..6)}, #{rand(0..4)}, #{rand(0..4)}, #{rand(0..4)}, #{rand(0..4)}, #{rand(0..6)}, #{rand(0..8)})")
    puts row
  end

end

desc "Seed the role frequencies based on 17 members"
task :role_frequencies do
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
  role_frequencies.each do |role, freq|
    con.exec("INSERT")
  end
end
