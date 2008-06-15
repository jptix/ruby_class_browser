class RCBSearcher < NSObject
  attr_writer :class_table, :method_table
  ib_outlets :search_table, :app_controller

  def awakeFromNib
    log("hello from RCBSearcher")
    log(@search_table, @app_controller)
  end

  def reset
    @results = []
    @search_table.reloadData
  end
  
  def find_classes(query)
    @results = []
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
    @search_table.reloadData
    @results
  end
  
  def find_methods(query)
    method_search(query)
    @search_table.reloadData
    @results
  end
  
  # ====================================================
	# = NSTableView (search results) data source methods =
	# ====================================================
  def tableView_objectValueForTableColumn_row(table_view, column, row)
    case res = @results[row]
    when RCBClassNode
      res.name
    when Array
      res.first
    end
  end
  
  def numberOfRowsInTableView(table_view)
    (@results ||= []).size
  end
  
  # =================================================
  # = NSTableView (search results) delegate methods =
  # =================================================
  def tableViewSelectionDidChange(notification)
    row = @search_table.selectedRow
    log(@results[row])
    
    case @results[row]
    when RCBClassNode
      @app_controller.select_node(@results[row])
    when Array
      @app_controller.select_method(*@results[row])
    end
  end

  def control_textView_doCommandBySelector(control, view, command)
    log(control, view, commend)
  end
  # control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command
  
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
      matches = @method_table.select { |method_name, method| Regexp.new(Regexp.escape(query), Regexp::IGNORECASE) =~ method_name }
    end
    @results = []
    matches.each do |method_name, method|
      method.instance_implementors.each { |node| @results << ["#{node.name}##{method_name}", node] }
      method.class_implementors.each { |node| @results << ["#{node.name}::#{method_name}", node] }
    end
    @results = @results.sort_by { |name, method| name }
  end


  
end