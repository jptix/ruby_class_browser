class RCBSearchWindowController < NSObject
  ib_outlets :window
  def initialize
    log @window
    super
  end
  
  def windowWillLoad
    log("loaded: #{@window}")
  end
  
  def show_window
    log(@window)
    @window.makeKeyAndOrderFront(self)
  end
  
  # =============================
  # = NSWindow delegate methods =
  # =============================
  def windowDidBecomeKey(notification)
    log("became key: #{@window}")
  end
  
  def windowDidResignKey(notification)
    log("resigned key: #{@window}")
    @window.orderOut(self)
  end
end