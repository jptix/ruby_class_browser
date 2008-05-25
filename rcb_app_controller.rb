require 'osx/cocoa'
include OSX

require_framework 'WebKit'

require "rcb_tree_constructor"
require "rcb_browser_cell"
require "rcb_doc_finder"
require "erb"

class RCBAppController < NSObject
	ib_outlets :browser, :table_view, :doc_view, :search_field,
	           :window, :toggle_button

  def initialize
    Thread.abort_on_exception = true
    @selected_cell = nil
    @methods = []
    @method_side = :instance
    @docs = RCBDocFinder.new
    @doc_template = File.read(File.dirname(__FILE__) + "/rcb_doc_template.erb")
  end

	def awakeFromNib
	  @browser.cellClass = RCBBrowserCell
	  @browser.delegate = self
	  @browser.maxVisibleColumns = 4
    @browser.takesTitleFromPreviousColumn = false

	  @table_view.dataSource = @table_view.delegate = self

	  @tree_constructor = RCBTreeConstructor.new
    @classes = @tree_constructor.create
	end
	
  def open(sender)
    panel = NSOpenPanel.openPanel
    if panel.runModalForTypes(%w(rb)) == NSOKButton
      begin
        panel.filenames.each { |f| require(f) }
      rescue Exception => e
        log(e.message)
        NSRunAlertPanel(e.class.name, e.message, "OK", "", "")
      end
    end
    @classes = @tree_constructor.create
  end

	def search(sender)
  	 node = @classes.values.find do |node|
  	   node.name.split("::").any? { |e| e.downcase == sender.stringValue.downcase }
  	 end
  	 
	   node ||= @classes.values.find do |node|
   	   node.name.split("::").any? { |e| Regexp.new(Regexp.escape(sender.stringValue), Regexp::IGNORECASE) =~ e }
   	 end
	  
	   if node
       path_for_node(node).each_with_index do |e, idx|
         if idx == 0
           @browser.selectRow_inColumn(0, 0)
    	   else
    	     @browser.selectRow_inColumn(@classes[e.superclass.name].subclasses.index(e), idx)
         end
    	 end
       browser_selection_changed
  	 end
	end
	
	def focus_search_field
	  @window.makeFirstResponder(@search_field)
	end

  def select_instance_side
    @toggle_button.selectedSegment = 0
    toggle_button_changed
  end

  def select_class_side
    @toggle_button.selectedSegment = 1
    toggle_button_changed
  end


	def browser_selection_changed(sender = nil)
	  update_method_table
	  show_documentation(@selected_class)
	end
	
	def toggle_button_changed
	  update_method_table
	end


	# ==============================
	# = NSBrowser delegate methods =
	# ==============================
  def browser_willDisplayCell_atRow_column(browser, cell, row, column)
    if column == 0
      current_node = @classes['Object']
    else
      parent_node = parent_node_for_column(column)
      log(parent_node) if row == 0
      current_node = parent_node.subclasses[row]
    end
    
    cell.leaf = true if current_node.subclasses.empty?
	  cell.stringValue = current_node.name
	  cell.node = current_node
  end
  
  def browser_numberOfRowsInColumn(browser, column)
    if column == 0
      1
    else
      parent_node_for_column(column).subclasses.size
    end
	end
	
	# ===================================
	# = NSTableView data source methods =
	# ===================================
  def tableView_objectValueForTableColumn_row(table_view, column, row)
    @methods[row]
  end
  
  def numberOfRowsInTableView(table_view)
    @methods.size
  end
  
  # ================================
  # = NSTableView delegate methods =
  # ================================
  def tableViewSelectionDidChange(notification)
    row = notification.object.selectedRow
    separator = @method_side == :instance ? '#' : '::'
    show_documentation(@selected_class + separator + @methods[row])
  end

	private

	def parent_node_for_column(column)
    unless column == 0
  	  @browser.selectedCellInColumn(column - 1).node
	  end
	end

  def path_for_node(node)
    path = [node]
    until (parent = node.superclass).nil?
      node = @classes[parent.name]
      path.unshift(node)
    end
    path
  end
  
  def show_documentation(query)
    result = @docs.find(query)
    body = result ? result.to_s : "Couldn't find documentation for #{query.inspect}"
    html = ERB.new(@doc_template).result(binding)
    @doc_view.mainFrame.loadHTMLString_baseURL(html, nil)   
  end

  def update_method_table
    if cell = @browser.selectedCell
      @selected_class = cell.node.name
      if @toggle_button.selectedSegment == 0
        @method_side = :instance
        @methods = cell.node.instance_methods
      else
        @method_side = :class
        @methods = cell.node.class_methods
      end
      @table_view.reloadData
    end
  end
  
  def select_first_method
    @table_view.selectRowIndexes_byExtendingSelection(NSIndexSet.indexSetWithIndex(0), false)
    separator = @method_side == :instance ? '#' : '::'
    show_documentation(@selected_class + separator + @methods[0])
  end
end

