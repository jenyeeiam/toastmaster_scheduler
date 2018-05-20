require 'csv'
require 'pg'
require 'pry'

con = PG.connect :dbname => 'toastmasters', :user => 'jennifer'

con.exec("drop table if exists members")
con.exec("create table members (id integer, name varchar(50), email varchar(50), speaker integer, evaluator integer, toastmaster integer, chair integer, ge integer, topics_master integer, functionary integer, tt_evaluator integer)")

CSV.foreach('/Users/jennifer/urbanlogiq/data/Club-Roster.csv', headers: true) do |row|
  con.exec("INSERT INTO members VALUES (#{row[row.first.first].to_i}, '#{row['Name']}', '#{row['Email']}', #{rand(0..6)}, #{rand(0..6)}, #{rand(0..4)}, #{rand(0..4)}, #{rand(0..4)}, #{rand(0..4)}, #{rand(0..6)}, #{rand(0..8)})")
end
