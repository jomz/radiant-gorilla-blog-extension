# Uncomment this if you reference any of your controllers in activate
require_dependency 'application'

class BlogExtension < Radiant::Extension
  version "1.0"
  description "A mashup of several extensions aiming to be a good basis for blogging"
  url "http://gorilla-webdesign.be"
  
  breaks_tests 'Admin::PagesControllerTest', %w{test_index__with_cookie} if respond_to?(:breaks_tests)
  
  define_routes do |map|                
    map.with_options(:controller => 'admin/tree_children') do |children| 
      children.tree_children 'admin/pages/:page_id/tree_children'
    end
  end
  
  def activate
    # admin_tree_structure stuff
    Admin::PagesController.send(:include, PagesControllerExtensions)
    Admin::NodeHelper.send(:include, NodeHelperChanges)
    ArchivePage.send(:include, ArchivePageTreeStructure)
    # blog_tags stuff
    Page.send(:include, BlogTags)
    
  end
  
  def deactivate
    # admin.tabs.remove "Blog"
  end
  
end