require_relative '../../app/repositories/condition_builder'

module ConditionBuilder


   describe SQL do
     test_scenarios = {
       "should create a where for attributes" => [{id: 4}, ["id = ?", 4]],
       "should handle OR" => [{wife_or: ['Wilma', 'Betty']}, ["(wife = 'Wilma' OR wife = 'Betty')"]],
       "should handle empty attributes" => [{first_name: 'Bob',last_name: '' }, ["first_name = ?", "Bob"]],
       "should handle nil" => [{first_name: 'Bob',last_name: nil }, ["first_name = ? AND last_name is NULL", "Bob"]],
       "should combine multiple attributes with AND" => [{id: 4, name: 'Bob'},["id = ? AND name = ?", 4, 'Bob'] ],
       "should handle like" => [{name_like: 'Fred'},["name LIKE ?", '%Fred%'] ],
       "should combine like and where" => [{kind: 'user', name_like: "Fred"}, ["kind = ? AND name LIKE ?", 'user', '%Fred%']],
       "should handle greater than" => [{count_gt: 4}, ["count > ?", 4]],
       "should handle less than" => [{count_lt: 4}, ["count < ?", 4]],
       "should handle IN" => [{wife_in: ['Wilma', 'Betty']}, ["wife IN ('Wilma', 'Betty')"]],
       "should handle all the things" => [{first_name: 'Fred', last_name_like: 'Flint', age_gt: 10, shoes_lt: 1, wife_in: ["Wilma", "Betty"]}, ["first_name = ? AND last_name LIKE ? AND age > ? AND shoes < ? AND wife IN ('Wilma', 'Betty')", "Fred" , "%Flint%", 10, 1 ]]
     }
   
     describe ".build" do
   
       test_scenarios.each_pair do |test_description, test_data|
         it test_description do
           conditions = ConditionBuilder::SQL.build(test_data[0])  
           conditions.should == test_data[1]
         end
       end
   
     end  
   end
  # 
  # describe Graph do
  #   test_scenarios = {
  #     "should create a where for attributes" => [{id: 4},["ID(x) = {xid}", {"xid"=>4}]],
  #     "should handle empty attributes" => [{first_name: 'Bob',last_name: '' },["x.first_name! = {first_name}", {"first_name"=>"Bob"}]],
  #     "should combine multiple attributes with AND" => [{id: 4, name: 'Bob'}, ["ID(x) = {xid} AND x.name! = {name}", {"xid"=>4, "name"=>"Bob"}] ],
  #     "should handle like" => [{name_like: 'Fred'}, ["x.name! =~ {name}", {"name"=>"(?i).*Fred.*"}] ],
  #     "should combine like and where" => [{kind: 'user', name_like: "Fred"}, ["x.kind! = {kind} AND x.name! =~ {name}", {"kind"=>"user", "name"=>"(?i).*Fred.*"}]],
  #     "should handle greater than" => [{count_gt: 4}, ["x.count! > {count}", {"count"=>4}]],
  #     "should handle less than" => [{count_lt: 4}, ["x.count! < {count}", {"count"=>4}]],
  #     "should handle IN" => [{wife_in: ['Wilma', 'Betty']}, ["x.wife! IN {wife}", {"wife"=>["Wilma", "Betty"]}]],
  #     "should handle all the things" => [{first_name: 'Fred', last_name_like: 'Flint', age_gt: 10, shoes_lt: 1, wife_in: ["Wilma", "Betty"]}, ["x.first_name! = {first_name} AND x.last_name! =~ {last_name} AND x.age! > {age} AND x.shoes! < {shoes} AND x.wife! IN {wife}", {"first_name"=>"Fred", "last_name"=>"(?i).*Flint.*", "age"=>10, "shoes"=>1, "wife"=>["Wilma", "Betty"]}]]
  #   }
  #   describe "build" do
  #     test_scenarios.each_pair do |test_description, test_data|
  #       it test_description do
  #         conditions = ConditionBuilder::Graph.build(test_data[0])  
  #         conditions.should == test_data[1]
  #       end
  #     end
  #   end
  # 
  # end
  
  describe OrientGraph do
    test_scenarios = {
      "should create a predicate for name attribute" => [{name: "bob"}, [["name", "EQUAL", "bob"]]],
      "should create a predicate for does not equal attribute" => [{name: "bob",  last_name_dne: "billy"}, [["name","EQUAL", "bob"], ["last_name", "NOT_EQUAL", "billy"]]],      
      "should create a predicate for greater than attribute" => [{cnt_gte: 10}, [["cnt", "GREATER_THAN_EQUAL", 10]]],      
      "should create a predicate for like attribute" => [{name_like: "ob"}, [["name","IN", '%ob%']]],            
      }
      # "should handle empty attributes" => [{first_name: 'Bob',last_name: '' },["x.first_name! = {first_name}", {"first_name"=>"Bob"}]],
      #       "should combine multiple attributes with AND" => [{id: 4, name: 'Bob'}, ["ID(x) = {xid} AND x.name! = {name}", {"xid"=>4, "name"=>"Bob"}] ],
      #       "should handle like" => [{name_like: 'Fred'}, ["x.name! =~ {name}", {"name"=>"(?i).*Fred.*"}] ],
      #       "should combine like and where" => [{kind: 'user', name_like: "Fred"}, ["x.kind! = {kind} AND x.name! =~ {name}", {"kind"=>"user", "name"=>"(?i).*Fred.*"}]],
      #       "should handle greater than" => [{count_gt: 4}, ["x.count! > {count}", {"count"=>4}]],
      #       "should handle less than" => [{count_lt: 4}, ["x.count! < {count}", {"count"=>4}]],
      #       "should handle IN" => [{wife_in: ['Wilma', 'Betty']}, ["x.wife! IN {wife}", {"wife"=>["Wilma", "Betty"]}]],
      #       "should handle all the things" => [{first_name: 'Fred', last_name_like: 'Flint', age_gt: 10, shoes_lt: 1, wife_in: ["Wilma", "Betty"]}, ["x.first_name! = {first_name} AND x.last_name! =~ {last_name} AND x.age! > {age} AND x.shoes! < {shoes} AND x.wife! IN {wife}", {"first_name"=>"Fred", "last_name"=>"(?i).*Flint.*", "age"=>10, "shoes"=>1, "wife"=>["Wilma", "Betty"]}]]
      #     }
    describe "build" do
      
      test_scenarios.each_pair do |test_description, test_data|
        it test_description do
          g = Oriented.graph
          g.raw_graph.transaction.close
          query = g.query()    
          query = ConditionBuilder::OrientGraph.build(query, test_data[0])  
          query.hasContainers.each_with_index{|h, index|
            h.key.should == test_data[1][index][0]
            h.predicate.name.should == test_data[1][index][1]
            h.value.should == test_data[1][index][2]
          }
        end
      end
    end
  end
  
end

