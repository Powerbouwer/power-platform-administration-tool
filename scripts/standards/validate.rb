require 'yaml'
require 'json'
require 'date'
require 'optparse'
require 'cgi'

module Standards
  class InputError < StandardError; end

  # Older native JSON parsers can bypass []= on Hash subclasses.
  class UniqueObject
    attr_reader :values

    def initialize
      @values = {}
    end

    def []=(key, value)
      raise InputError, 'Duplicate JSON property' if @values.key?(key)
      @values[key] = value
    end
  end

  DOCS = {
    'FLOW-NAME' => 'naming#flow-name',
    'APP-NAME' => 'naming#app-name',
    'FLOW-VAR-NAME' => 'naming#flow-var-name',
    'FLOW-VAR-SCOPE' => 'cloud-flows#flow-var-scope',
    'CANVAS-DESCRIPTION' => 'canvas-apps#canvas-description',
    'CANVAS-SCREEN' => 'naming#canvas-screen',
    'CANVAS-CONTROL' => 'naming#canvas-control',
    'CANVAS-UNIQUE' => 'naming#canvas-unique',
    'SOURCE-COVERAGE' => 'ci-validation#source-coverage'
  }.freeze

  TYPES = {
    'modernflows' => 'cloud_flow', 'canvasapps' => 'canvas_app',
    'appmodules' => 'model_driven_app', 'entities' => 'dataverse',
    'entityrelationships' => 'dataverse', 'optionsets' => 'dataverse',
    'roles' => 'dataverse'
  }.freeze

  def self.read_data(path)
    raise InputError, 'Expected source file is missing' unless File.file?(path)
    raise InputError, 'Source file exceeds the 8 MiB inspection limit' if File.size(path) > 8 * 1024 * 1024
    text = File.read(path, encoding: 'UTF-8')
    if File.extname(path).downcase == '.json'
      plain_json(JSON.parse(text, object_class: UniqueObject))
    else
      tree = Psych.parse_stream(text)
      raise InputError, 'Expected exactly one YAML document' unless tree.children.length == 1
      pending = [[tree, 0]]
      until pending.empty?
        node, depth = pending.pop
        raise InputError, 'YAML nesting exceeds the inspection limit' if depth > 100
        if node.respond_to?(:tag) && node.tag &&
           !%w[str int float bool null timestamp map seq].any? { |type| node.tag == "tag:yaml.org,2002:#{type}" }
          raise InputError, 'YAML object/custom tags are not supported'
        end
        if node.is_a?(Psych::Nodes::Mapping)
          keys = node.children.each_slice(2).map do |key, _value|
            raise InputError, 'Complex YAML keys are not supported' unless key.is_a?(Psych::Nodes::Scalar)
            raise InputError, 'YAML merge keys are not supported' if key.value == '<<'
            if (key.tag && key.tag != 'tag:yaml.org,2002:str') ||
               (!key.quoted && !key.tag && !YAML.safe_load(key.value).is_a?(String))
              raise InputError, 'YAML mapping keys must be text; quote implicitly typed keys'
            end
            key.value
          end
          raise InputError, 'Duplicate YAML property' unless keys.uniq.length == keys.length
        end
        pending.concat((node.children || []).map { |child| [child, depth + 1] })
      end
      YAML.safe_load(text, permitted_classes: [Time, Date], aliases: false)
    end
  rescue Psych::Exception, JSON::ParserError, EncodingError, ArgumentError => e
    raise InputError, "Invalid or unsupported source data (#{e.class})"
  end

  def self.plain_json(value)
    case value
    when UniqueObject
      value.values.to_h { |key, child| [key, plain_json(child)] }
    when Array
      value.map { |child| plain_json(child) }
    else
      value
    end
  end

  def self.object(value, property)
    raise InputError, "Expected an object at #{property}" unless value.is_a?(Hash)
    value
  end

  def self.list(value, property)
    raise InputError, "Expected a list at #{property}" unless value.is_a?(Array)
    value
  end

  def self.inside?(root, path)
    path == root || path.start_with?(root + File::SEPARATOR)
  end

  def self.safe_path(root, reference)
    raise InputError, 'Expected a nonempty source path' unless reference.is_a?(String) && !reference.strip.empty?
    relative = reference.tr('\\', '/')
    if relative.start_with?('//') || relative.match?(/\A[A-Za-z]:/) ||
       relative.split('/').include?('..') || relative.include?("\0")
      raise InputError, 'Source path escapes its solution'
    end
    path = File.expand_path(relative.sub(/\A\//, ''), root)
    raise InputError, 'Source path escapes its solution' unless inside?(root, path)
    ancestor = path
    ancestor = File.dirname(ancestor) until File.exist?(ancestor) || File.symlink?(ancestor)
    raise InputError, 'Source symlink escapes its solution' unless inside?(root, File.realpath(ancestor))
    path
  rescue Errno::ENOENT, Errno::ELOOP
    raise InputError, 'Source path has a broken symlink'
  end

  def self.escape_command(value, property: false)
    text = value.to_s.gsub('%', '%25').gsub("\r", '%0D').gsub("\n", '%0A')
    property ? text.gsub(':', '%3A').gsub(',', '%2C') : text
  end

  def self.markdown(value)
    CGI.escapeHTML(value.to_s).gsub(/([\\`*_\[\]{}|])/, '\\\\\1').gsub(/[\r\n]/, ' ')
  end

  class Validator
    attr_reader :result

    def initialize(root:, base:, changed_files:, policy: File.join(__dir__, 'policy.yml'))
      @root = File.realpath(root)
      @severity = base == 'main' ? 'error' : 'warning'
      @changes = changed_files
      @policy = Standards.object(Standards.read_data(policy), 'policy')
      raise InputError, 'Unexpected policy properties' unless @policy.keys.sort == %w[control_prefixes variable_prefixes]
      @policy.each_value do |prefixes|
        Standards.object(prefixes, 'prefixes').each do |type, prefix|
          unless type.is_a?(String) && prefix.is_a?(String) && prefix.match?(/\A[a-z]{3,4}\z/)
            raise InputError, 'Invalid prefix policy'
          end
        end
      end
      unless @policy['variable_prefixes'] == {
        'string' => 'str', 'integer' => 'int', 'float' => 'flt',
        'boolean' => 'bool', 'array' => 'arr', 'object' => 'obj'
      }
        raise InputError, 'Variable policy must cover the agreed six declared types'
      end
      @result = { 'status' => 'not_applicable', 'solution' => nil, 'counts' => TYPES.values.uniq.to_h { |t| [t, 0] },
                  'out_of_scope' => [], 'findings' => [] }
      @resource = { 'type' => 'solution', 'identity' => '', 'name' => '' }
    end

    def finding(rule, file, property, expected, found, advice)
      @result['findings'] << {
        'rule' => rule, 'severity' => @severity, 'solution' => @result['solution'],
        'resource_type' => @resource['type'], 'resource_id' => @resource['identity'],
        'resource_name' => @resource['name'], 'file' => file, 'property' => property,
        'expected' => expected, 'found' => found.to_s[0, 200],
        'advice' => advice, 'docs' => "docs/developer/standards/#{DOCS.fetch(rule).sub('#', '.md#')}"
      }
    end

    def coverage(file, property, reason)
      finding('SOURCE-COVERAGE', file, property, 'Readable supported source', reason,
              'Restore the source or verify the export and add a tested parser; do not treat missing coverage as compliance.')
    end

    def source(relative)
      Standards.object(Standards.read_data(Standards.safe_path(@solution_root, relative)), relative)
    end

    def run
      changes = Standards.list(@changes, 'changed files')
      paths = changes.flatten(1).flat_map do |change|
        if change.is_a?(Hash)
          filename = change.fetch('filename') { raise InputError, 'Changed file has no filename' }
          [filename, change['previous_filename']].compact
        else
          [change]
        end
      end
      raise InputError, 'Changed paths must be strings' unless paths.all? { |p| p.is_a?(String) }
      candidates = paths.filter_map { |p| p.tr('\\', '/').match(%r{\Asolutions/([^/]+)/})&.captures&.first }.uniq.sort
      return finish if candidates.empty?
      if candidates.length != 1
        @result['status'] = 'selection_error'
        coverage('', 'changed paths', "Multiple changed solutions: #{candidates.join(', ')}")
        return finish
      end
      @result['solution'] = candidates.first
      @resource['identity'] = candidates.first
      @resource['name'] = candidates.first
      relative_root = File.join('solutions', candidates.first)
      @solution_root = Standards.safe_path(@root, relative_root)
      unless File.directory?(@solution_root)
        @result['status'] = 'deleted'
        if paths.any? { |p| p.tr('\\', '/').start_with?("solutions/#{candidates.first}/") } &&
           changes.flatten(1).all? { |c| c.is_a?(Hash) && (c['status'] == 'removed' || !c['filename'].start_with?("solutions/#{candidates.first}/")) }
          return finish
        end
        coverage(relative_root, 'solution', 'Changed solution directory is missing')
        return finish
      end
      @result['status'] = 'checked'
      begin
        manifest = source(File.join('solutions', candidates.first, 'solution.yml'))
        name = manifest.dig('ImportExportXml', 'SolutionManifest', 'UniqueName')
        raise InputError, 'Solution manifest identity does not match its directory' unless name == candidates.first
        component_file = File.join('solutions', candidates.first, 'solutioncomponents.yml')
        document = source(component_file)
        components = document.dig('SolutionComponents', 'Component')
        components = [] if components.nil? && document['SolutionComponents'].is_a?(Hash) && document['SolutionComponents'].key?('Component')
        entries = components.is_a?(Hash) ? [components] : Standards.list(components, 'SolutionComponents.Component')
        references = entries.map { |c| Standards.object(c, 'Component').fetch('@path') { raise InputError, 'Component has no @path' } }
        raise InputError, 'Component paths must be strings' unless references.all? { |p| p.is_a?(String) }
        references = references.map { |r| r.tr('\\', '/').sub(/\A\//, '').sub(%r{/\z}, '') }.uniq.sort
        references.each { |reference| inspect_component(reference) }
        TYPES.each_key do |folder|
          directory = Standards.safe_path(@solution_root, folder)
          next unless File.directory?(directory)
          Dir.children(directory).sort.each do |component|
            next if component == '.gitkeep'
            relative = "#{folder}/#{component}"
            next if references.any? { |r| r == relative || r.start_with?(relative + '/') }
            @resource = { 'type' => TYPES.fetch(folder), 'identity' => relative, 'name' => component }
            coverage(repo_file(relative), 'membership', 'Resource directory/file is not listed in solutioncomponents.yml')
          end
        end
      rescue InputError, TypeError => e
        coverage(relative_root, 'manifest', e.is_a?(InputError) ? e.message : 'Malformed manifest structure')
      end
      finish
    end

    def inspect_component(reference)
      relative = reference.tr('\\', '/').sub(/\A\//, '')
      folder = relative.split('/').first
      type = TYPES[folder]
      unless type
        @result['out_of_scope'] << relative
        return
      end
      @resource = { 'type' => type, 'identity' => relative, 'name' => File.basename(relative) }
      @result['counts'][type] += 1
      begin
        path = Standards.safe_path(@solution_root, reference)
        raise InputError, 'Component directory is missing' unless File.directory?(path)
        case type
        when 'cloud_flow' then inspect_flow(relative)
        when 'canvas_app' then inspect_canvas(relative)
        when 'model_driven_app' then inspect_model_app(relative)
        else coverage(repo_file(relative), 'component', 'Dataverse table/column/form/view/role/choice export is not yet verified')
        end
      rescue InputError, TypeError => e
        coverage(repo_file(relative), 'source', e.is_a?(InputError) ? e.message : 'Malformed resource structure')
      end
    end

    def repo_file(relative)
      File.join('solutions', @result['solution'], relative).tr('\\', '/')
    end

    def name_check(name, rule, relative, property, parts)
      values = name.is_a?(String) ? name.split(' - ', -1) : []
      valid = values.length == parts || (rule == 'FLOW-NAME' && values.length == 4 && values[1] == 'Child Flow')
      valid &&= values.all? { |s| !s.strip.empty? && s == s.strip && !s.match?(/[\r\n]/) }
      return if valid
      expected = rule == 'FLOW-NAME' ? 'Module - Domain/Process - Purpose (optional Child Flow segment)' : 'Module - Purpose'
      finding(rule, repo_file(relative), property, expected, name,
              'Set a meaningful display name in the supported designer; preserve technical IDs and references.')
    end

    def inspect_flow(relative)
      file = File.join(relative, 'workflow.yml')
      metadata = Standards.object(source(file).fetch('Workflow', nil), 'Workflow')
      @resource['name'] = metadata['@Name'].to_s
      raise InputError, 'Expected Category 5 cloud flow metadata' unless metadata['Category'].to_s == '5'
      raise InputError, 'Cloud flow identity is missing' unless metadata['@WorkflowId'].is_a?(String) && !metadata['@WorkflowId'].empty?
      name_check(metadata['@Name'], 'FLOW-NAME', file, 'Workflow.@Name', 3)
      json_file = metadata.fetch('JsonFileName', nil)
      data = source(json_file)
      definition = Standards.object(data.dig('properties', 'definition'), 'properties.definition')
      triggers = Standards.object(definition['triggers'], 'triggers')
      raise InputError, 'Cloud flow must have a trigger' if triggers.empty?
      triggers.each_value { |t| Standards.object(t, 'trigger').fetch('type') { raise InputError, 'Trigger type is missing' } }
      walk_actions(definition['actions'], json_file.sub(/\A\//, ''), 'properties.definition.actions', 0)
    end

    def walk_actions(actions, file, property, depth)
      raise InputError, 'Action nesting exceeds the inspection limit' if depth > 100
      Standards.object(actions, property).each do |name, value|
        action = Standards.object(value, "#{property}.#{name}")
        location = "#{property}.#{name}"
        type = action.fetch('type') { raise InputError, 'Action type is missing' }
        if type == 'InitializeVariable'
          if depth.positive?
            finding('FLOW-VAR-SCOPE', repo_file(file), location, 'Top-level initialization', 'Nested initialization',
                    'Initialize the variable at global flow level.')
          end
          variables = action.dig('inputs', 'variables')
          Standards.list(variables, "#{location}.inputs.variables").each do |variable|
            variable = Standards.object(variable, 'variable')
            prefix = @policy['variable_prefixes'][variable['type'].to_s.downcase]
            raise InputError, 'Unsupported declared flow variable type' unless prefix
            next if variable['name'].is_a?(String) && variable['name'].match?(/\A#{prefix}[A-Z][A-Za-z0-9]*\z/)
            finding('FLOW-VAR-NAME', repo_file(file), "#{location}.inputs.variables.name",
                    "#{prefix} followed by a PascalCase purpose", variable['name'], 'Rename through the designer and update dependent expressions.')
          end
        end
        walk_actions(action['actions'], file, "#{location}.actions", depth + 1) if action.key?('actions')
        if action.key?('else')
          alternative = Standards.object(action['else'], "#{location}.else")
          walk_actions(alternative['actions'], file, "#{location}.else.actions", depth + 1)
        end
        if action.key?('cases')
          Standards.object(action['cases'], "#{location}.cases").each do |key, branch|
            walk_actions(Standards.object(branch, 'case')['actions'], file, "#{location}.cases.#{key}.actions", depth + 1)
          end
        end
        if action.key?('default')
          walk_actions(Standards.object(action['default'], 'default')['actions'], file, "#{location}.default.actions", depth + 1)
        end
        if %w[Scope Foreach Until If].include?(type) && !action.key?('actions')
          raise InputError, 'Container action has no actions object'
        end
        raise InputError, 'Switch action has no cases object' if type == 'Switch' && !action.key?('cases')
      end
    end

    def inspect_model_app(relative)
      file = File.join(relative, 'appmodule.yml')
      metadata = Standards.object(source(file)['AppModule'], 'AppModule')
      names = metadata.dig('LocalizedNames', 'LocalizedName')
      names = [names] if names.is_a?(Hash)
      Standards.list(names, 'LocalizedNames.LocalizedName').each do |entry|
        name = Standards.object(entry, 'LocalizedName')['@description']
        @resource['name'] = name.to_s
        name_check(name, 'APP-NAME', file, "LocalizedNames.#{entry['@languagecode']}", 2)
      end
      raise InputError, 'No localized app display names' if names.empty?
    end

    def inspect_canvas(relative)
      file = File.join(relative, 'canvasapp.yml')
      metadata = Standards.object(source(file)['CanvasApp'], 'CanvasApp')
      @resource['name'] = metadata['DisplayName'].to_s
      name_check(metadata['DisplayName'], 'APP-NAME', file, 'CanvasApp.DisplayName', 2)
      description = metadata['Description']
      unless description.is_a?(String) && !description.strip.empty?
        finding('CANVAS-DESCRIPTION', repo_file(file), 'CanvasApp.Description', 'Nonempty app description',
                'Missing or empty description', 'Describe the users and business task in Power Apps Studio.')
      end
      uri = metadata['DocumentUri']
      raise InputError, 'Expected native .msapp DocumentUri' unless uri.is_a?(String) && uri.end_with?('.msapp')
      src_reference = uri.tr('\\', '/').sub(/\A\//, '').sub(/\.msapp\z/, '') + '/Src'
      src = Standards.safe_path(@solution_root, src_reference)
      raise InputError, 'Unpacked Canvas Src directory is missing; binary-only apps cannot be inspected' unless File.directory?(src)
      files = Dir.glob('**/*.pa.yaml', base: src).reject { |p| File.basename(p) == '_EditorState.pa.yaml' }.sort
      raise InputError, 'No unpacked Canvas YAML files' if files.empty?
      seen = {}
      screen_count = 0
      files.each do |path|
        source_file = File.join(src_reference, path)
        begin
          document = Standards.object(source(source_file), 'Canvas YAML')
          unknown = document.keys - %w[App Screens]
          raise InputError, 'Unsupported Canvas root (including component-definition namespaces)' unless unknown.empty?
          Standards.object(document['App'], 'App') if document.key?('App')
          next unless document.key?('Screens')
          Standards.object(document['Screens'], 'Screens').each do |name, screen|
            screen_count += 1
            unique_name(name, seen, source_file, "Screens.#{name}")
            unless name.match?(/\A[A-Z][A-Za-z0-9]*(?: [A-Z][A-Za-z0-9]*)* Screen\z/)
              finding('CANVAS-SCREEN', repo_file(source_file), "Screens.#{name}", 'Plain-language Title Case name ending in Screen',
                      name, 'Choose a readable screen name and verify screen reader output.')
            end
            screen = Standards.object(screen, 'Screen')
            walk_controls(screen.fetch('Children', []), seen, source_file, "Screens.#{name}.Children")
          end
        rescue InputError, TypeError => e
          coverage(repo_file(source_file), 'Canvas YAML', e.is_a?(InputError) ? e.message : 'Malformed Canvas structure')
        end
      end
      raise InputError, 'No Canvas screens could be inspected' if screen_count.zero?
    end

    def unique_name(name, seen, file, property)
      raise InputError, 'Canvas name must be text' unless name.is_a?(String)
      if seen.key?(name)
        finding('CANVAS-UNIQUE', repo_file(file), property, 'Unique name across the app', name,
                'Rename in Studio, use a purpose/screen suffix and update references.')
      end
      seen[name] = true
    end

    def walk_controls(children, seen, file, property)
      Standards.list(children, property).each do |child|
        child = Standards.object(child, property)
        raise InputError, 'Each Canvas child must contain exactly one named control' unless child.length == 1
        name, value = child.first
        control = Standards.object(value, "#{property}.#{name}")
        unique_name(name, seen, file, "#{property}.#{name}")
        type = control['Control']
        raise InputError, 'Canvas Control type is missing' unless type.is_a?(String)
        type = type.split('@').first.delete_prefix('Classic/')
        prefix = @policy['control_prefixes'][type]
        if prefix.nil?
          coverage(repo_file(file), "#{property}.#{name}.Control", "Unmapped control type: #{type}")
        elsif !name.match?(/\A#{prefix}[A-Z][A-Za-z0-9]*(?:_[A-Za-z0-9]+)*\z/)
          finding('CANVAS-CONTROL', repo_file(file), "#{property}.#{name}", "#{prefix} followed by a PascalCase purpose",
                  name, 'Rename in Studio and update references; a uniqueness suffix is optional.')
        end
        walk_controls(control['Children'], seen, file, "#{property}.#{name}.Children") if control.key?('Children')
      end
    end

    def finish
      @result['out_of_scope'].sort!.uniq!
      @result['findings'].sort_by! { |f| [f['solution'].to_s, f['resource_type'], f['resource_id'], f['file'], f['property'], f['rule']] }
      @result
    end

    def exit_code
      return 2 if @result['status'] == 'selection_error'
      @result['findings'].any? { |f| f['severity'] == 'error' } ? 1 : 0
    end
  end

  def self.report(result, summary_path: nil)
    result['findings'].each do |f|
      text = "#{f['rule']}: #{f['resource_name']} / #{f['property']}. Expected #{f['expected']}; found #{f['found']}. #{f['advice']} See #{f['docs']}."
      puts "::#{f['severity']} file=#{escape_command(f['file'], property: true)},title=#{escape_command(f['rule'], property: true)}::#{escape_command(text)}"
    end
    lines = ['## Power Platform standards', '', "**Status:** #{markdown(result['status'])}  ",
             "**Active solution:** #{markdown(result['solution'] || 'none; no changed solution directory')}  ",
             "**Findings:** #{result['findings'].length}", '',
             '| Resource type | Components discovered / inspection attempted |', '| --- | ---: |']
    result['counts'].each { |type, count| lines << "| #{type} | #{count} |" }
    lines << ''
    lines << 'Dataverse table/column/form/view checks and Power Fx semantics are not yet automated. Out-of-scope components are not standards failures.'
    lines << "Out-of-scope component references: #{result['out_of_scope'].length}."
    result['findings'].group_by { |f| f['resource_type'] }.each do |type, findings|
      lines.concat(['', "### #{type}", '', '| Severity / rule | Resource / location | Expected / found | Remedy |',
                    '| --- | --- | --- | --- |'])
      findings.each do |f|
        cells = ["#{f['severity']} / #{f['rule']}", "#{f['resource_name']} / #{f['file']} / #{f['property']}",
                 "#{f['expected']} / #{f['found']}", "#{f['advice']} (#{f['docs']})"]
        repository = ENV.fetch('GITHUB_REPOSITORY', 'Powerbouwer/power-platform-administration-tool')
        server = ENV.fetch('GITHUB_SERVER_URL', 'https://github.com')
        reference = ENV.fetch('STANDARDS_DOCS_REF', 'main')
        link = "#{server}/#{repository}/blob/#{reference}/#{f['docs']}"
        lines << "| #{cells.map { |c| markdown(c) }.join(' | ')} [Docs](#{link}) |"
      end
    end
    summary = lines.join("\n") + "\n"
    File.write(summary_path, summary) if summary_path
    puts summary
  end
end

if $PROGRAM_NAME == __FILE__
  begin
    options = { root: Dir.pwd }
    parser = OptionParser.new do |o|
      o.on('--root PATH') { |v| options[:root] = v }
      o.on('--base BRANCH') { |v| options[:base] = v }
      o.on('--changed-files PATH') { |v| options[:changes] = v }
      o.on('--policy PATH') { |v| options[:policy] = v }
      o.on('--report PATH') { |v| options[:report] = v }
      o.on('--summary PATH') { |v| options[:summary] = v }
    end
    parser.parse!
    raise Standards::InputError, 'Use --base BRANCH and --changed-files PATH' unless options[:base] && options[:changes] && ARGV.empty?
    arguments = { root: options[:root], base: options[:base], changed_files: Standards.read_data(options[:changes]) }
    arguments[:policy] = options[:policy] if options[:policy]
    validator = Standards::Validator.new(**arguments)
    result = validator.run
    File.write(options[:report], JSON.pretty_generate(result) + "\n") if options[:report]
    Standards.report(result, summary_path: options[:summary])
    exit validator.exit_code
  rescue Standards::InputError, OptionParser::ParseError, SystemCallError => e
    warn "::error title=Standards execution failure::#{Standards.escape_command(e.message)}"
    exit 2
  end
end
