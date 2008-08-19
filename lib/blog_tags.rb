module BlogTags
  include Radiant::Taggable

  class TagError < StandardError; end
  
  desc %{
    Render a list of blog items. Finds all articles for a blog, and provides links to them in a workable markup.
    <strong>Usage:</strong>
    
    <pre><code><r:archive_list blog="/news" [hmtl_id="archive"] [mention_author="false"]/></code></pre>
    
    <strong>Attributes:</strong>
    
    blog: required. the path to the blog's root.
    html_id: defaults to none. becomes the HTML id attribute of the main ul
    mention_author: defaults to true. Set to false to not mention the author of each news item
    
    <strong>Example output:</strong>
    
    <pre><ul class="archive">
      <li>2008<ul class="months">
          <li>February<ul class="articles">
              <li><a href="/news/2008/02/30/article-title/">Article breadcrumb</a></li>
            </ul>
          </li>
        </ul>
      </li>
    </ul></pre>
  }
  
  tag "archive_list" do |tag|
    raise TagError, "archive_list tag requires a 'blog' attribute." unless tag.attr['blog']
    html_id = !tag.attr['html_id'].nil? ? " id=\"#{tag.attr['html_id'] }\"" : ""
    mention_author = true unless tag.attr['mention_author'] && tag.attr['mention_author'] == 'false'
    list = ""
    # readyup contents
    blog = Page.find_by_url tag.attr['blog']
    blog.tree_children.each do |year|
      list << "<li>#{year.title}<ul class=\"months\">"
      year.tree_children.each do |month|
        published = month.tree_children.delete_if{|c| !c.published? }
        if published.length > 0
          list << "<li>#{month.title} <span class=\"amount\">(#{published.length})</span><ul class=\"articles\">"
            published.each do |article|
              list << "<li><a href=\"#{article.url}\">#{article.title}</a><span class=\"metadata\"> "
              list << "door <span class=\"author\">#{article.created_by.name}</span> " if mention_author
              list << "op <span class=\"date\">#{article.published_at.strftime("%d/%m/%Y")}</span>"
              list << "</span></li>"
            end
          list << "</ul></li>"
        end
      end
      list << "</ul></li>"
    end
    # output
    %{<ul#{html_id} class="archive">
      #{list}
    </ul>}
  end
  
  desc %{
    <r:archive_items_in url="" />
      // works as children:each..
    </r:archive_items_in>
  }
  
  tag "archive_items_in" do |tag|
    result = []
    options = array_options(tag)
    children = find_archive_items_in(tag.attr['url'], options[:status])
    return "No items matching criteria" if children.nil?
    # apply limit & order options
    eval "children.sort! {|x,y| x.#{options[:by]} <=> y.#{options[:by]} }"
    children.reverse! if options[:order] == 'desc'
    children = children[0..(options[:limit]-1)]
    
    tag.locals.previous_headers = {}
    children.compact.each do |item|
      tag.locals.child = item
      tag.locals.page = item
      result << tag.expand
    end 
    result
  end
  
  desc %{ Run through escape_once
    <strong>Usage:</strong>
    <pre><code><r:escape><r:title /></r:escape></code></pre>
  }
  
  tag "escape" do |tag|
    escape_once(tag.expand)
  end
  
  ## stolen from search extension
  
  desc %{    <r:truncate_and_strip [length="100"] />
    Truncates and strips all HTML tags from the content of the contained block.  
    Useful for displaying a snippet of a found page.  The optional `length' attribute
    specifies how many characters to truncate to.
  }

  tag 'truncate_and_strip' do |tag|
    tag.attr['length'] ||= 100
    length = tag.attr['length'].to_i
    helper = ActionView::Base.new
    helper.truncate(helper.strip_tags(tag.expand).gsub(/\s+/," "), length)
  end
  
  ## from the original blog_tags extension
  
  tag "next" do |tag|
    current = tag.locals.page
    by = (tag.attr['by'] || 'published_at').strip
    
    unless current.attributes.keys.include?(by)
      raise TagError.new("`by' attribute of `next' tag must be set to a valid page attribute name")
    end
        
    # get the page's siblings, exclude any that have nil 
    # for the sorting attribute, exclude virtual pages,
    # and sort by the chosen attribute
    siblings = current.self_and_siblings.delete_if { |s| s.send(by).nil? || s.virtual? }.sort_by { |page| page.attributes[by] }
    index = siblings.index(current)
    next_page = siblings[index + 1]
  
    if next_page
      tag.locals.page = next_page
      tag.expand
    end
  end

  tag "previous" do |tag|
    current = tag.locals.page    
    by = (tag.attr['by'] || 'published_at').strip
    
    unless current.attributes.keys.include?(by)
      raise TagError.new("`by' attribute of `previous' tag must be set to a valid page attribute name")
    end
        
    siblings = current.self_and_siblings.delete_if { |s| s.send(by).nil? || s.virtual? }.sort_by { |page| page.attributes[by] }
    index = siblings.index(current)

    # we don't want to wrap around to the last article  
    # when we're at the first article  
    previous = index > 0 ? siblings[index - 1] : nil
    
    if previous
      tag.locals.page = previous
      tag.expand
    end
  end
  
  tag "time_ago_in_words" do |tag|
    ActionView::Base.new.time_ago_in_words(tag.locals.page.published_at || tag.locals.page.created_at)
  end
  
  private
  
  def find_archive_items_in(url, status = "")
    result = []
    container = Page.find_by_url url
    container.children.each do |child|
      if child.class_name.eql?("ArchivePage") && child.status_id == status
        child.children.each {|c| result << c }
      else
        result << find_archive_items_in(child.url, status) unless find_archive_items_in(child.url, status).nil? || child.children.empty?
      end 
    end
    result.flatten.empty? ? nil : result
  end
  
  # stolen from standard_tags.rb
  def array_options(tag)
    attr = tag.attr.symbolize_keys
    
    options = {}
    
    [:limit, :offset].each do |symbol|
      if number = attr[symbol]
        if number =~ /^\d{1,4}$/
          options[symbol] = number.to_i
        else
          raise TagError.new("`#{symbol}' attribute must be a positive number between 1 and 4 digits")
        end
      end
    end
    
    by = (attr[:by] || 'published_at').strip
    order = (attr[:order] || 'desc').strip
    order_string = ''
    if self.attributes.keys.include?(by)
      order_string << by
    else
      raise TagError.new("`by' attribute must be set to a valid field name")
    end
    if order =~ /^(asc|desc)$/i
      order_string << " #{$1.upcase}"
    else
      raise TagError.new(%{`order' attribute must be set to either "asc" or "desc"})
    end
    # options[:order] = order_string
    options[:by] = by
    options[:order] = order
    status = (attr[:status] || 'published').downcase
    unless status == 'all'
      stat = Status[status]
      unless stat.nil?
        options[:status] = stat.id
      else
        raise TagError.new(%{`status' attribute must be set to a valid status})
      end
    end
    options
  end
  
end