require 'osx/cocoa'
include OSX

require_framework 'WebKit'
require "ri_outputter/lib/ri_outputter"

class RCBAppController < NSObject
	ib_outlets :browser, :table_view, :doc_view, :search_panel, :search_field,
	           :window, :toggle_button, :searcher

  def initialize
    Thread.abort_on_exception = true
    @selected_cell = nil
    @methods = []
    @method_side = :instance
    @ri = RiOutputter::Lookup.new(
      :lookup_order    => [:exact, :exact_ci, :nested],
      :template_folder => File.dirname(__FILE__) + "/ri_outputter/lib/ri_outputter/templates/ruby_class_browser"
    )
  end

	def awakeFromNib
    @table_view.dataSource = @table_view.delegate = @browser.delegate = self
	  @browser.cellClass = RCBBrowserCell
	  @browser.maxVisibleColumns = 4
    @browser.takesTitleFromPreviousColumn = false

	  @tree_constructor = RCBTreeConstructor.new
    @tree_constructor.create
    @classes      = @tree_constructor.classes
    @method_table = @tree_constructor.methods

    @browser.selectRow_inColumn(0, 0) 
    browser_selection_changed
    
    log @classes.find { |k,v| k == "CGI::Cookie"}
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
  
  def open_search_window(sender)
    @search_panel.makeKeyAndOrderFront(self)
    @search_field.becomeFirstResponder
  end

	def search(sender)
	  @searcher.class_table = @classes
	  @searcher.method_table = @method_table
	  query = sender.stringValue
	  if query.empty?
	    @searcher.reset
      @browser.selectRow_inColumn(0, 0) 
      return browser_selection_changed
    end
    
    if query.to_ruby =~ /[A-Z]/
      unless(nodes = @searcher.find_classes(query)).empty?
        select_node(nodes.first)
      end
    else
      @searcher.find_methods(query)
    end
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
	  tableViewSelectionDidChange(nil)
	end

  def select_node(node)
    log("selecting node: #{node.inspect}")
    path_for_node(node).each_with_index do |e, idx|
     if idx == 0
       @browser.selectRow_inColumn(0, 0)
     else
       @browser.selectRow_inColumn(@classes[e.superclass.name].subclasses.index(e), idx)
     end
    end
    browser_selection_changed
  end
  
  def select_method(method_name, node)
    select_node(node)
    log(method_name)
    if method_name[/(\w+)(#|::)(\w+)$/]
      klass = $1
      $2 == '#' ? select_instance_side : select_class_side
      method = $3
      if idx = @methods.index(method)
        @table_view.selectRow_byExtendingSelection(idx, false)
        @table_view.scrollRowToVisible(idx)
      end
    end
    
  end


	# ==============================
	# = NSBrowser delegate methods =
	# ==============================
  def browser_willDisplayCell_atRow_column(browser, cell, row, column)
    if column == 0
      current_node = @classes['Object']
    else
      parent_node = parent_node_for_column(column)
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
	
	# ==================================================
	# = NSTableView (method table) data source methods =
	# ==================================================
  def tableView_objectValueForTableColumn_row(table_view, column, row)
    @methods[row]
  end
  
  def numberOfRowsInTableView(table_view)
    @methods.size
  end
  
  # ===============================================
  # = NSTableView (method table) delegate methods =
  # ===============================================
  def tableViewSelectionDidChange(notification)
      row = @table_view.selectedRow
      separator = @method_side == :instance ? '#' : '::'
      show_documentation(@selected_class + separator + @methods[row].to_s)
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
      break unless node = @classes[parent.name]
      path.unshift(node)
    end
    path
  end
  
  def show_documentation(query)
    begin 
      html = @ri.html_for(query)
    rescue
      html = nil
    end
    @doc_view.mainFrame.loadHTMLString_baseURL(html || "<h3>Nothing found for #{e_html query.inspect}</h3>", nil)   
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
    show_documentation(@selected_class + separator + @methods[0].to_s)
  end
  
  def e_html(text); text.gsub(/&/, '&amp;').gsub(/</, '&lt;').gsub(/>/, '&gt;') end
end

