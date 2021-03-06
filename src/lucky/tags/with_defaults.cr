# Set up defaults arguments for HTML tags.
#
# This is automatically included in Pages and Cells.
module Lucky::WithDefaults
  # This is typically used in Cells and helper methods to set up defaults for
  # reusable components.
  #
  # Example in a page or cell:
  #
  #    with_defaults field: form.email, class: "input" do |html|
  #      html.email_input placeholder: "Email"
  #    end
  #
  # Is the same as:
  #
  #     email_input field: form.email, class: "input", placeholder: "Email"
  def with_defaults(**named_args)
    OptionMerger.new(page_context: self, named_args: named_args).run do |html|
      yield html
    end
  end

  class OptionMerger(T, V)
    def initialize(@page_context : T, @named_args : V)
    end

    def run
      yield self
    end

    macro method_missing(call)
      overridden_html_class = nil

      {% named_args = call.named_args %}
      {% if named_args %}
        {% if call.named_args.any? { |arg| arg.name == :class } %}
          {% raise <<-ERROR


          Use 'replace_class' or 'append_class' instead of 'class'.

          Correct example:

              with_defaults class: "default" do |html|
                # Use 'replace_class' or 'append_class' here
                html.div replace_class: "replaced"
              end

          Incorrect example:

              with_defaults class: "default" do |html|
                # Won't work with 'class'
                html.div class: "replaced"
              end

          -----------------

          ERROR
          %}
        {% end %}

        {% appended_class_arg = call.named_args.find { |arg| arg.name == :append_class } %}
        {% if appended_class_arg %}
          overridden_html_class = "#{@named_args[:class]?} #{{{ appended_class_arg.value }}}"
        {% end %}
        {% named_args = named_args.reject { |arg| arg.name == :append_class } %}

        {% replace_class_arg = call.named_args.find { |arg| arg.name == :replace_class } %}
        {% if replace_class_arg %}
          overridden_html_class = "#{{{ replace_class_arg.value }}}"
        {% end %}
        {% named_args = named_args.reject { |arg| arg.name == :replace_class } %}
      {% end %}

      args = @named_args{% if named_args %}.merge(
        {% for arg in named_args %}
          {{ arg.name }}: {{ arg.value }},
        {% end %}
      )
      if overridden_html_class
        args = args.merge(class: overridden_html_class)
      end
      {% end %}

      @page_context.{{ call.name }} **args
    end
  end
end
