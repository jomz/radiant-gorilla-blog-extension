class Admin::TreeChildrenController < ApplicationController
  
  def index
    id, *tree_children = params[:page_id].split('_')
    @parent = tree_children.inject(Page.find(id)) {|current, slug| current.tree_child(slug) }
    @level = params[:level].to_i
    @controller_name = 'pages'
    @template_name = 'index'
    response.headers['Content-Type'] = 'text/html;charset=utf-8'
    render(:controller => 'admin/pages', :action => 'children.html.erb', :layout => false, :locals => {:models => @parent.tree_children})
  end
  
end