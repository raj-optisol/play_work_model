class CypherToJsonSerializer
  
  
  def self.format_paths(paths)
    h = {}

    paths.each{|p| 
        pointer = h;        
        p.reverse_each{|c|           
          if c.respond_to?('getType')            
            pointer['permissions'] = c[:permission_sets] if c[:permission_sets]
          else
            pointer[c["_classname"]] = {} unless pointer[c["_classname"]]
            gg = pointer[c["_classname"]][c.id] || c.props
            pointer[c["_classname"]][c.id] = gg          
            pointer = gg
          end
        }  
    }
    return h
  end
  
end