require 'osx/cocoa'
include OSX

require_framework 'WebKit'

require "rcb_tree_constructor"
require "rcb_browser_cell"
require "rcb_doc_finder"
require "erb"

class RCBAppController < NSObject
	ib_outlets :browser, :table_view, :doc_view, :search_field

  def initialize
    Thread.abort_on_exception = true
    @selected_cell = nil
    @methods = []
    @docs = RCBDocFinder.new
    @doc_template = File.read(File.dirname(__FILE__) + "/rcb_doc_template.erb")
  end

	def awakeFromNib
	  @browser.setCellClass(RCBBrowserCell)
	  @browser.setDelegate(self)
	  @browser.setMaxVisibleColumns(4)
    @browser.setTakesTitleFromPreviousColumn(false)

	  
	  @table_view.setDataSource(self)
	  @table_view.setDelegate(self)

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
    	 update_method_table
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
    
    cell.setLeaf(true) if current_node.subclasses.empty?
	  cell.setStringValue(current_node.name)
	  cell.node = current_node
  end
  
  def browser_numberOfRowsInColumn(browser, column)
    if column == 0
      1
    else
      parent_node_for_column(column).subclasses.size
    end
	end
	
	def browser_selection_changed(sender)
	  update_method_table
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
    Thread.new do
      row = notification.object.selectedRow
      show_documentation_for_method(@methods[row])
    end
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
  
  def show_documentation_for_method(method)
    full_name = "#{@selected_class}##{method}"
    result = @docs.find(full_name)
    body = result ? result.to_s : "Couldn't find #{full_name}"
    html = ERB.new(@doc_template).result(binding)
    @doc_view.mainFrame.loadHTMLString_baseURL(html, nil)   
  end

  def update_method_table
    if cell = @browser.selectedCell
      @selected_class = cell.node.name
      @methods = cell.node.instance_methods
      @table_view.reloadData
      select_first_method
    end
  end
  
  def select_first_method
    @table_view.selectRowIndexes_byExtendingSelection(NSIndexSet.indexSetWithIndex(0), false)
    show_documentation_for_method(@methods[0])
  end
end

