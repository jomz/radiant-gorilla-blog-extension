module PagesControllerExtensions
  def self.included(clazz)
    clazz.class_eval do
      
      def index
        @homepage = Page.find_by_parent_id(nil)
        if params[:page_id] && (Page.find(params[:page_id]).class_name == 'ArchivePage') || params[:page_id] =~ /_/
          return redirect_to tree_children_url(:params => {:level => params[:level]})
        end
        respond_to do |format|
          format.html
          format.js do
            @level = params[:level].to_i
            @template_name = 'index'
            response.headers['Content-Type'] = 'text/html;charset=utf-8'
            render :action => 'children.html.haml', :layout => false
          end
          format.xml { render :xml => models }
        end
      end      
      
      def children
        id, *tree_children = params[:id].split('_')
        @parent = tree_children.inject(Page.find(id)) {|current, slug| current.tree_child(slug) }
         @level = params[:level].to_i
         response.headers['Content-Type'] = 'text/html;charset=utf-8'
         render(:layout => false)
      end
      before_filter :include_admin_tree_javascript, :only => :index
      private
        def include_admin_tree_javascript
          @content_for_page_scripts ||= ''
          @content_for_page_scripts <<(<<-EOF)
	    Object.extend(SiteMap.prototype, {
	      extractPageId: function(row) {
	        if (/page-([\\d]+(_[\\d_A-Z]+)?)/i.test(row.id)) {
	          return RegExp.$1;
		      }
	      },
	      getBranch: function(row) {
          var id = this.extractPageId(row), level = this.extractLevel(row),
              spinner = $('busy-' + id);
          if(id.include("_")){
      			new Ajax.Updater(
      				row,
      				'/admin/pages/' + id + '/tree_children?level=' + level,
      				{
      					insertion: "after",
      					onLoading:  function() { spinner.show(); this.updating = true  }.bind(this),
      	        onComplete: function() { spinner.fade(); this.updating = false }.bind(this),
      	        method: 'get'
      				}
      			);
      		}
          else{
      			new Ajax.Updater(
            	row,
      	      '/admin/pages/' + id + '/children?level=' + level,
      	      {
      	        insertion: "after",
      	        onLoading:  function() { spinner.show(); this.updating = true  }.bind(this),
      	        onComplete: function() { spinner.fade(); this.updating = false }.bind(this),
      	        method: 'get'
      	      }
      	    );
      		}
        }
	    });
	  EOF
        end
    end
  end
end
