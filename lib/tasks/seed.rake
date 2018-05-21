require 'csv'
require 'pry'

desc "Seed the members from csv club roster"
task :seed_members do
  Member.delete_all
  CSV.foreach('lib/tasks/Club-Roster.csv', headers: true) do |row|
    Member.create(
      id: row[row.first.first].to_i,
      name: row['Name'],
      email: row['Email'],
      speaker: rand(0..6),
      evaluator: rand(0..6),
      toastmaster: rand(0..4),
      chair: rand(0..4),
      ge: rand(0..4),
      topics_master: rand(0..4),
      functionary: rand(0..6),
      tt_evaluator: rand(0..8)
    )
    puts row
  end

end
