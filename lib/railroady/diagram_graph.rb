# RailRoady - RoR diagrams generator
# http://railroad.rubyforge.org
#
# Copyright 2007-2008 - Javier Smaldone (http://www.smaldone.com.ar)
# See COPYING for more details


# RailRoady diagram structure
class DiagramGraph

  def initialize
    @diagram_type = ''
    @show_label   = false
    @alphabetize  = false
    @nodes = []
    @edges = []
  end

  def add_node(node)
    @nodes << node
  end

  def add_edge(edge)
    @edges << edge
  end

  def diagram_type= (type)
    @diagram_type = type
  end

  def show_label= (value)
    @show_label = value
  end

  def alphabetize= (flag)
    @alphabetize = flag
  end


  # Generate DOT graph
  def to_dot
    return dot_header +
           @nodes.map{|n| dot_node n[0], n[1], n[2], n[3]}.join +
           @edges.map{|e| dot_edge e[0], e[1], e[2], e[3]}.join +
           dot_footer
  end

  # Generate XMI diagram (not yet implemented)
  def to_xmi
     STDERR.print "Sorry. XMI output not yet implemented.\n\n"
     return ""
  end

  private

  # Build DOT diagram header
  def dot_header
    result = "digraph #{@diagram_type.downcase}_diagram {\n" +
             "\tgraph[overlap=false, splines=true, bgcolor=\"none\"]\n"
    result += dot_label if @show_label
    return result
  end

  # Build DOT diagram footer
  def dot_footer
    return "}\n"
  end

  # Build diagram label
  def dot_label
    return "\t_diagram_info [shape=\"plaintext\", " +
           "label=\"#{@diagram_type} diagram\\l" +
           "Date: #{Time.now.strftime "%b %d %Y - %H:%M"}\\l" +
           (defined?(ActiveRecord::Migrator) ? "Migration version: " +
            "#{ActiveRecord::Migrator.current_version}\\l" : "") +
           "Generated by #{APP_HUMAN_NAME} #{APP_VERSION}\\l"+
		   "http://railroady.prestonlee.com" +
           "\\l\", fontsize=13]\n"
  end

  # Build a DOT graph node
  def dot_node(type, name, attributes=nil, custom_options='')
    case type
      when 'model'
           options = 'shape=Mrecord, label="{' + name + '|'
           options += attributes.sort_by { |s| @alphabetize ? s : nil }.join('\l')
           options += '\l}"'
      when 'model-brief'
           options = ''
      when 'class'
           options = 'shape=record, label="{' + name + '|}"'
      when 'class-brief'
           options = 'shape=box'
      when 'controller'
           options = 'shape=Mrecord, label="{' + name + '|'
           public_methods    = attributes[:public].sort_by    { |s| @alphabetize ? s : nil }.join('\l')
           protected_methods = attributes[:protected].sort_by { |s| @alphabetize ? s : nil }.join('\l')
           private_methods   = attributes[:private].sort_by   { |s| @alphabetize ? s : nil }.join('\l')
           options += public_methods + '\l|' + protected_methods + '\l|' +
                      private_methods + '\l'
           options += '}"'
      when 'controller-brief'
           options = ''
      when 'module'
           options = 'shape=box, style=dotted, label="' + name + '"'
      when 'aasm'
           # Return subgraph format
           return "subgraph cluster_#{name.downcase} {\n\tlabel = #{quote(name)}\n\t#{attributes.join("\n  ")}}"
    end # case
    options = [options, custom_options].compact.join(', ')
    return "\t#{quote(name)} [#{options}]\n"
  end # dot_node

  # Build a DOT graph edge
  def dot_edge(type, from, to, name = '')
    options =  name != '' ? "label=\"#{name}\", " : ''
    edge_color = '"#%02X%02X%02X"' % [rand(255), rand(255), rand(255)]
    suffix = ", dir=both color=#{edge_color}"
    case type
      when 'one-one'
           options += "arrowtail=odot, arrowhead=dot" + suffix
      when 'one-many'
           options += "arrowtail=odot, arrowhead=crow" + suffix
      when 'many-many'
           options += "arrowtail=crow, arrowhead=crow" + suffix
      when 'belongs-to'
           # following http://guides.rubyonrails.org/association_basics.html#the-belongs-to-association
           options += "arrowtail=none, arrowhead=normal" + suffix
      when 'is-a'
           options += 'arrowhead="none", arrowtail="onormal"'
      when 'event'
           options += "fontsize=10"
    end
    return "\t#{quote(from)} -> #{quote(to)} [#{options}]\n"
  end # dot_edge

  # Quotes a class name
  def quote(name)
    '"' + name.to_s + '"'
  end

end # class DiagramGraph
