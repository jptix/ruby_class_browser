class RCBSearcher < NSObject
  attr_writer :class_table, :method_table
  ib_outlets :search_table
    
  def find_classes(query)
    log("showing color")
    @table.gridColor
    log("done showing color")
    nodes = @class_table.values.select do |node|
      if node.name.split("::").any? { |e| e.downcase == query.downcase }
        @results << node
      end
    end
    log("reloading first time")

    nodes ||= @class_table.values.select do |node|
      if node.name.split("::").any? { |e| Regexp.new(Regexp.escape(query), Regexp::IGNORECASE) =~ e }
        @results << node
      end 
    end
    log("reloading second time")
    # @table.setNeedsDisplayInRect(@table.frameOfCellAtColumn(0, @results.size - 1))    
    
    @results
  end
  
  def find_methods(query)
    
  end
  
  # ===================================
	# = NSTableView data source methods =
	# ===================================
  def tableView_objectValueForTableColumn_row(table_view, column, row)
    log("displaying row: #{row}")
    @results[row]
  end
  
  def numberOfRowsInTableView(table_view)
    (@results ||= []).size
  end

  private
	
  def class_search(query)
    node = @classes.values.find do |node|
     node.name.split("::").any? { |e| e.downcase == query.downcase }
    end

    node ||= @classes.values.find do |node|
       node.name.split("::").any? { |e| Regexp.new(Regexp.escape(query), Regexp::IGNORECASE) =~ e }
    end
  end
  
  def method_search(query)
    matches = [[query, @method_table[query.to_s]]]
    if matches[0][1].empty?
      matches = @method_table.select { |method, nodes| Regexp.new(Regexp.escape(query), Regexp::IGNORECASE) =~ method }
    end
    @method_search_results = []
    matches.each do |method, nodes|
      nodes.each { |node| @method_search_results << ["#{node.name} #{method}", node] }
    end
    @method_search_results = @method_search_results.sort_by { |name, node| name }
  end


  
end