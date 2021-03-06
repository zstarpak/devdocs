module Docs
  class Css
    class EntriesFilter < Docs::EntriesFilter
      TYPE_BY_PATH = {
        'CSS_Animations' => 'Animations & Transitions',
        'CSS_Background_and_Borders' => 'Backgrounds & Borders',
        'CSS_Columns' => 'Multi-column Layout',
        'CSS_Flexible_Box_Layout' => 'Flexible Box Layout',
        'CSS_Images' => 'Image Values',
        'CSS_Lists_and_Counters' => 'Lists & Counters',
        'CSS_Transforms' => 'Transforms',
        'Media_Queries' => 'Media Queries',
        '@media' => 'Media Queries',
        'transform-function' => 'Transforms',
        'text-size-adjust' => 'Miscellaneous',
        'resolved_value' => 'Miscellaneous',
        'touch-action' => 'Miscellaneous',
        'will-change' => 'Miscellaneous',
        'align-self' => 'Flexible Box Layout'
      }

      DATA_TYPE_SLUGS = %w(angle basic-shape color_value counter frequency
        gradient image integer length number percentage position_value ratio
        resolution shape string time timing-function uri user-ident)

      FUNCTION_SLUGS = %w(attr calc cross-fade cubic-bezier cycle element
        linear-gradient radial-gradient repeating-linear-gradient
        repeating-radial-gradient var)

      def get_name
        if DATA_TYPE_SLUGS.include?(slug)
          "<#{super.remove ' value'}>"
        elsif FUNCTION_SLUGS.include?(slug)
          "#{super}()"
        elsif slug =~ /\A[a-z]+_/i
          slug.to_s.gsub('_', ' ').gsub('/', ': ')
        elsif slug.start_with?('transform-function')
          slug.split('/').last + '()'
        else
          super
        end
      end

      def get_type
        if slug.include?('-webkit') || slug.include?('-moz')
          'Extensions'
        elsif type = TYPE_BY_PATH[slug.split('/').first]
          type
        elsif type = get_spec
          type.remove! 'CSS '
          type.remove! ' Module'
          type.remove! %r{ Level \d\z}
          type.remove! %r{\(.*\)}
          type.sub! 'and', '&'
          type.strip!
          type = 'Animations & Transitions' if type.in?(%w(Animations Transitions))
          type = 'Image Values' if type == 'Image Values & Replaced Content'
          type = 'Variables' if type == 'Custom Properties for Cascading Variables'
          type.prepend 'Miscellaneous ' if type =~ /\ALevel \d\z/
          type
        elsif name.start_with?('::')
          'Pseudo-Elements'
        elsif name.start_with?(':')
          'Selectors'
        else
          'Miscellaneous'
        end
      end

      STATUSES = {
        'spec-Living' => 0,
        'spec-REC'    => 1,
        'spec-CR'     => 2,
        'spec-LC'     => 3,
        'spec-WD'     => 4,
        'spec-ED'     => 5
      }

      PRIORITY_STATUSES = %w(spec-REC spec-CR)
      PRIORITY_SPECS = ['CSS Basic Box Model', 'CSS Lists and Counters', 'CSS Paged Media']

      def get_spec
        return unless table = at_css('#Specifications + table') || css('.standard-table').last
        specs = table.css('tbody tr').to_a
        # [link, span]
        specs.map!     { |node| [node.at_css('> td:nth-child(1) > a'), node.at_css('> td:nth-child(2) > span')] }
        # ignore non-CSS specs
        specs.select!  { |pair| pair.first && pair.first['href'] =~ /css|fxtf|fullscreen|svg/i && !pair.first['href'].include?('compat.spec') }
        # ["Spec", "spec-REC"]
        specs.map!     { |pair| [pair.first.child.content, pair.second['class']] }
        # sort by status
        specs.sort_by! { |pair| [STATUSES[pair.second], pair.first] }

        spec = specs.find { |pair| PRIORITY_SPECS.any? { |s| pair.first.start_with?(s) } && name != 'display' }
        spec ||= specs.find { |pair| !pair.first.start_with?('CSS Level') && pair.second.in?(PRIORITY_STATUSES) }
        spec ||= specs.find { |pair| pair.second == 'spec-WD' } if specs.count { |pair| pair.second == 'spec-WD' } == 1
        spec ||= specs.first

        spec.try(:first)
      end

      ADDITIONAL_ENTRIES = {
        'shape' => [
          %w(rect() Syntax) ],
        'uri' => [
          %w(url() The_url()_functional_notation) ],
        'timing-function' => [
          %w(cubic-bezier() The_cubic-bezier()_class_of_timing-functions),
          %w(steps() The_steps()_class_of_timing-functions),
          %w(linear linear),
          %w(ease ease),
          %w(ease-in ease-in),
          %w(ease-in-out ease-in-out),
          %w(ease-out ease-out),
          %w(step-start step-start),
          %w(step-end step-end) ],
        'color_value' => [
          %w(transparent transparent_keyword),
          %w(currentColor currentColor_keyword),
          %w(rgb() rgb),
          %w(hsl() hsl),
          %w(rgba() rgba),
          %w(hsla() hsla) ]}

      def additional_entries
        ADDITIONAL_ENTRIES[slug] || []
      end

      def include_default_entry?
        return true unless warning = at_css('.warning').try(:content)
        !warning.include?('CSS Flexible Box') && !warning.include?('replaced in newer drafts')
      end
    end
  end
end
