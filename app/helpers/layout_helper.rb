module LayoutHelper

  def body_classes
    # Join the route together, and compact them down
    # if any parts are missing, then join them together
    # with a space.
    classes = [
      route.controller, # eg. "queue"
      current_path.strip('/').gsub(/\//, '-') # eg. "/foo/bar" => "foo-bar"
    ].reject { |p|
      p.blank? 
    }.join(" ")

    classes.blank? ? "root" : classes
  end

end
