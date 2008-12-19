# Uncomment this if you reference any of your controllers in activate
require_dependency 'application'

class BlogExtension < Radiant::Extension
  version "1.0"
  description "A mashup of several extensions aiming to be a good basis for blogging"
  url "http://gorilla-webdesign.be"
  
  breaks_tests 'Admin::PagesControllerTest', %w{test_index__with_cookie} if respond_to?(:breaks_tests)
  
  def activate
    # admin_tree_structure stuff
    Admin::PagesController.send(:include, PageControllerChildren)
    Admin::NodeHelper.send(:include, NodeHelperChanges)
    ArchivePage.send(:include, ArchivePageTreeStructure)
    # blog_tags stuff
    Page.send(:include, BlogTags)
    
  end
  
  def deactivate
    # admin.tabs.remove "Blog"
  end
  
end