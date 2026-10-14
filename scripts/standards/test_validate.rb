require_relative 'validate'
require 'tmpdir'
require 'fileutils'
require 'open3'
require 'rbconfig'

def assert(condition, message = 'Assertion failed')
  raise message unless condition
end

def write_data(path, value)
  FileUtils.mkdir_p(File.dirname(path))
  File.write(path, File.extname(path) == '.json' ? JSON.pretty_generate(value) : YAML.dump(value))
end

def solution(root, name, components = [])
  directory = File.join(root, 'solutions', name)
  write_data(File.join(directory, 'solutions', name, 'solution.yml'),
             { 'ImportExportXml' => { 'SolutionManifest' => { 'UniqueName' => name } } })
  write_data(File.join(directory, 'solutions', name, 'solutioncomponents.yml'),
             { 'SolutionComponents' => { 'Component' => components.map { |p| { '@path' => "/#{p}" } } } })
  directory
end

FLOW_ID = 'ca27d5d6-2bc3-f111-a05c-70a8a507ac5b'
FLOW_JSON = 'PPAT-SearchInventory-CA27D5D6-2BC3-F111-A05C-70A8A507AC5B.json'
FIXTURES = File.join(__dir__, 'fixtures')
CASES = {}

def check(name, &block)
  CASES[name] = block
end

def flow(directory, id = FLOW_ID, name = 'PPAT - Inventory - Search Resources')
  path = File.join(directory, 'modernflows', id)
  FileUtils.mkdir_p(path)
  metadata = Standards.read_data(File.join(FIXTURES, 'inventory-search', 'workflow.yml'))
  metadata['Workflow']['@WorkflowId'] = "{#{id}}"
  metadata['Workflow']['@Name'] = name
  metadata['Workflow']['JsonFileName'] = "/modernflows/#{id}/#{FLOW_JSON}"
  write_data(File.join(path, 'workflow.yml'), metadata)
  FileUtils.cp(File.join(FIXTURES, 'inventory-search', FLOW_JSON), path)
  path
end

def validate(root, name = 'a', base = 'main', changes = nil, **options)
  validator = Standards::Validator.new(root: root, base: base,
    changed_files: changes || ["solutions/#{name}/some-change.yml"], **options)
  [validator.run, validator.exit_code]
end

def variable(name, type)
  { 'type' => 'InitializeVariable', 'inputs' => { 'variables' => [{ 'name' => name, 'type' => type }] } }
end

def mutate_flow(path)
  filename = File.join(path, FLOW_JSON)
  data = JSON.parse(File.read(filename))
  yield data['properties']['definition']
  write_data(filename, data)
end

check('native flow envelope, app trigger and actual action notes') do |root|
  directory = solution(root, 'a', ["modernflows/#{FLOW_ID}"])
  path = flow(directory, FLOW_ID, 'PPAT - Search Inventory')
  result, code = validate(root, 'a', 'release')
  assert(code.zero?)
  assert(result['counts']['cloud_flow'] == 1)
  assert(result['findings'].map { |f| f['rule'] } == ['FLOW-NAME'])
  data = Standards.read_data(File.join(path, FLOW_JSON))
  assert(data.dig('properties', 'definition', 'triggers', 'manual', 'kind') == 'PowerAppV2')
  assert(data.dig('properties', 'definition', 'actions', 'Respond_to_App', 'runAfter').key?('Search_Inventory'))
end

check('all resources in only the changed solution, also unchanged offenders') do |root|
  a = solution(root, 'a', ["modernflows/#{FLOW_ID}", 'modernflows/second'])
  b = solution(root, 'b', ["modernflows/#{FLOW_ID}"])
  flow(a)
  flow(a, 'second', 'Invalid Name')
  flow(b, FLOW_ID, 'Also Invalid')
  result, code = validate(root)
  assert(code == 1 && result['solution'] == 'a')
  assert(result['counts']['cloud_flow'] == 2)
  assert(result['findings'].all? { |f| f['solution'] == 'a' && f['resource_id'].end_with?('second') })
  result, = validate(root, 'b')
  assert(result['counts']['cloud_flow'] == 1 && result['findings'].all? { |f| f['solution'] == 'b' })
end

check('exact main target, warnings elsewhere and child name format') do |root|
  directory = solution(root, 'a', ["modernflows/#{FLOW_ID}"])
  flow(directory, FLOW_ID, 'Invalid')
  %w[main main-copy core/v1.0.0/release core/v1.0.0/spr-70].each do |base|
    result, code = validate(root, 'a', base)
    assert(code == (base == 'main' ? 1 : 0))
    assert(result['findings'].all? { |f| f['severity'] == (base == 'main' ? 'error' : 'warning') })
  end
  flow(directory, FLOW_ID, 'PPAT - Child Flow - Inventory - Search Resources')
  assert(validate(root).last.zero?)
end

check('docs only, removed solution and ambiguous rename selection') do |root|
  assert(validate(root, 'a', 'main', ['docs/index.md']).first['status'] == 'not_applicable')
  removed, code = validate(root, 'a', 'main', [{ 'filename' => 'solutions/a/old.yml', 'status' => 'removed' }, { 'filename' => 'docs/index.md', 'status' => 'modified' }])
  assert(removed['status'] == 'deleted' && code.zero?)
  result, code = validate(root, 'a', 'release', [
    [{ 'filename' => 'solutions/b/new.yml', 'previous_filename' => 'solutions/a/old.yml', 'status' => 'renamed' }]
  ])
  assert(result['status'] == 'selection_error' && code == 2)
  assert(result['counts'].values.sum.zero?)
end

check('missing solution is not a successful deletion') do |root|
  result, code = validate(root)
  assert(code == 1 && result['findings'].any? { |f| f['rule'] == 'SOURCE-COVERAGE' })
end

check('deduplicated component references and out-of-scope types') do |root|
  directory = solution(root, 'a', ["modernflows/#{FLOW_ID}", "modernflows/#{FLOW_ID}/", 'connectionreferences/broken', 'connectors/broken'])
  flow(directory)
  result, code = validate(root)
  assert(code.zero? && result['counts']['cloud_flow'] == 1)
  assert(result['out_of_scope'].length == 2)
end

check('unlisted resource is a coverage finding, not an omitted scan') do |root|
  directory = solution(root, 'a')
  flow(directory)
  result, code = validate(root)
  assert(code == 1 && result['findings'].any? { |f| f['property'] == 'membership' })
end

check('dataverse is counted but not falsely supported') do |root|
  directory = solution(root, 'a', ['entities/ppat_certificate'])
  FileUtils.mkdir_p(File.join(directory, 'entities', 'ppat_certificate'))
  result, code = validate(root)
  assert(code == 1 && result['counts']['dataverse'] == 1)
  assert(result['findings'].first['rule'] == 'SOURCE-COVERAGE')
end

check('all six variable types and nested conditions/scopes/loops/switch branches') do |root|
  directory = solution(root, 'a', ["modernflows/#{FLOW_ID}"])
  path = flow(directory)
  mutate_flow(path) do |definition|
    definition['actions'] = %w[string integer float boolean array object].zip(%w[str int flt bool arr obj]).to_h do |type, prefix|
      [type, variable("#{prefix}Purpose", type)]
    end
  end
  assert(validate(root).last.zero?)
  mutate_flow(path) do |definition|
    definition['actions'] = {
      'Scope' => { 'type' => 'Scope', 'actions' => { 'Init' => variable('bad', 'string') } },
      'Loop' => { 'type' => 'Foreach', 'actions' => { 'Init' => variable('intCount', 'integer') } },
      'Until' => { 'type' => 'Until', 'actions' => { 'Init' => variable('intCount', 'integer') } },
      'If' => { 'type' => 'If', 'actions' => {}, 'else' => { 'actions' => { 'Init' => variable('intCount', 'integer') } } },
      'Switch' => { 'type' => 'Switch', 'cases' => { 'A' => { 'actions' => { 'Init' => variable('intCount', 'integer') } } },
                    'default' => { 'actions' => { 'Init' => variable('intCount', 'integer') } } }
    }
  end
  result, = validate(root)
  assert(result['findings'].count { |f| f['rule'] == 'FLOW-VAR-SCOPE' } == 6)
  assert(result['findings'].count { |f| f['rule'] == 'FLOW-VAR-NAME' } == 1)
end

check('native canvas metadata, timestamps, nil descriptions and full child traversal') do |root|
  component = 'canvasapps/ppat_ppattemplate_97904'
  directory = solution(root, 'a', [component])
  path = File.join(directory, component)
  FileUtils.mkdir_p(path)
  FileUtils.cp(File.join(FIXTURES, 'canvas', 'canvasapp.yml'), path)
  src = File.join(path, 'ppat_ppattemplate_97904_DocumentUri', 'Src')
  FileUtils.mkdir_p(src)
  FileUtils.cp(File.join(FIXTURES, 'canvas', 'Screen Form.pa.yaml'), src)
  result, = validate(root)
  assert(result['findings'].map { |f| f['rule'] }.sort == %w[CANVAS-DESCRIPTION CANVAS-SCREEN], result['findings'].inspect)
  screen = { 'Screens' => { 'Home Screen' => { 'Children' => [
    { 'conLayout' => { 'Control' => 'GroupContainer@1.5.0', 'Children' => [
      { 'btnSave_1' => { 'Control' => 'ModernButton@1.0.0' } },
      { 'badButton' => { 'Control' => 'Classic/Button@2.2.0' } }
    ] } }
  ] } } }
  write_data(File.join(src, 'Screen Form.pa.yaml'), screen)
  write_data(File.join(src, 'Other.pa.yaml'), { 'Screens' => { 'Other Screen' => { 'Children' => [
    { 'btnSave_1' => { 'Control' => 'ModernButton@1.0.0' } },
    { 'newType' => { 'Control' => 'UnverifiedControl@1.0' } }
  ] } } })
  result, = validate(root)
  assert(result['findings'].count { |f| f['rule'] == 'CANVAS-CONTROL' } == 1)
  assert(result['findings'].count { |f| f['rule'] == 'CANVAS-UNIQUE' } == 1)
  assert(result['findings'].any? { |f| f['rule'] == 'SOURCE-COVERAGE' })
  metadata = Standards.read_data(File.join(path, 'canvasapp.yml'))
  [nil, '', " \n "].each do |description|
    metadata['CanvasApp']['Description'] = description
    write_data(File.join(path, 'canvasapp.yml'), metadata)
    assert(validate(root).first['findings'].any? { |f| f['rule'] == 'CANVAS-DESCRIPTION' })
  end
  metadata['CanvasApp']['Description'] = 'Administration task.'
  write_data(File.join(path, 'canvasapp.yml'), metadata)
  assert(validate(root).first['findings'].none? { |f| f['rule'] == 'CANVAS-DESCRIPTION' })
end

check('model-driven localized display names, not schema identity') do |root|
  directory = solution(root, 'a', ['appmodules/module'])
  path = File.join(directory, 'appmodules', 'module')
  FileUtils.mkdir_p(path)
  FileUtils.cp(File.join(FIXTURES, 'model-driven', 'appmodule.yml'), path)
  result, = validate(root)
  assert(result['findings'].map { |f| f['rule'] } == ['APP-NAME'])
  write_data(File.join(path, 'appmodule.yml'), { 'AppModule' => { 'UniqueName' => 'generated_name',
    'LocalizedNames' => { 'LocalizedName' => [
      { '@description' => 'PPAT - Administration', '@languagecode' => 1033 },
      { '@description' => 'Invalid', '@languagecode' => 1043 }
    ] } } })
  assert(validate(root).first['findings'].count { |f| f['rule'] == 'APP-NAME' } == 1)
end

check('missing, malformed and wrong-envelope sources are coverage findings') do |root|
  directory = solution(root, 'a', ["modernflows/#{FLOW_ID}", 'modernflows/absent'])
  path = flow(directory)
  File.write(File.join(path, FLOW_JSON), '{"definition": {}}')
  result, = validate(root)
  assert(result['findings'].count { |f| f['rule'] == 'SOURCE-COVERAGE' } == 2)
  ['{', '{"properties":{"definition":[]}}'].each do |content|
    File.write(File.join(path, FLOW_JSON), content)
    assert(validate(root).first['findings'].any? { |f| f['rule'] == 'SOURCE-COVERAGE' })
  end
end

check('parser rejects duplicate properties, object tags, aliases and multiple YAML documents') do |root|
  samples = {
    'duplicate.yml' => "A: 1\nA: 2\n", 'duplicate.json' => '{"A":1,"A":2}',
    'nested-duplicate.json' => '{"root":[{"A":1,"A":2}]}',
    'escaped-duplicate.json' => '{"A":1,"\\u0041":2}',
    'tag.yml' => "--- !ruby/object:Object {}\n",
    'date-tag.yml' => "--- !ruby/object:Date {}\n",
    'merge.yml' => "A:\n  <<: {B: 1}\n  B: 2\n",
    'implicit-keys.yml' => "on: 1\ntrue: 2\n",
    'alias.yml' => "A: &x [1]\nB: *x\n", 'documents.yml' => "---\nA: 1\n---\nB: 2\n",
    'complex.yml' => "? [A, B]\n: 1\n", 'deep.yml' => 'A: ' + '[' * 110 + '1' + ']' * 110
  }
  samples.each do |name, content|
    path = File.join(root, name)
    File.write(path, content)
    begin
      Standards.read_data(path)
      raise "Accepted invalid data: #{name}"
    rescue Standards::InputError
      # Expected rejection.
    end
  end
end

check('source paths cannot traverse or follow symlinks out of the solution') do |root|
  directory = solution(root, 'a', ["modernflows/#{FLOW_ID}"])
  path = flow(directory)
  %w[/../outside.json C:/outside.json //server/share.json].each do |reference|
    metadata = Standards.read_data(File.join(path, 'workflow.yml'))
    metadata['Workflow']['JsonFileName'] = reference
    write_data(File.join(path, 'workflow.yml'), metadata)
    assert(validate(root).first['findings'].any? { |f| f['rule'] == 'SOURCE-COVERAGE' })
  end
  link = File.join(directory, 'external')
  begin
    File.symlink(root, link)
  rescue NotImplementedError, Errno::EACCES, Errno::EPERM
    puts 'SKIP filesystem symlink case: this host cannot create symbolic links.'
  else
    begin
      Standards.safe_path(File.realpath(directory), 'external/secret.json')
      raise 'Accepted external symlink'
    rescue Standards::InputError
      # Expected rejection.
    ensure
      File.unlink(link)
    end
  end
end

check('JSON string escapes, surrogate pairs and literal merge-like property names are preserved') do |root|
  path = File.join(root, 'unicode.json')
  File.write(path, '{"\\uD83D\\uDE00":"\\uD83D\\uDE00","<<":"literal","escaped":"quote: \\" and slash: \\\\","zero":"\\u0000"}')
  data = Standards.read_data(path)
  assert(data["\u{1F600}"] == "\u{1F600}")
  assert(data['<<'] == 'literal')
  assert(data['escaped'] == "quote: \" and slash: \\")
  assert(data['zero'] == "\0")
end

check('configuration failure is execution failure even on warning branches') do |root|
  policy = File.join(root, 'policy.yml')
  write_data(policy, { 'control_prefixes' => {}, 'variable_prefixes' => {} })
  begin
    validate(root, 'a', 'release', [], policy: policy)
    raise 'Accepted incomplete policy'
  rescue Standards::InputError
    # Expected rejection.
  end
end

check('annotations and Markdown escape untrusted metadata; all docs anchors exist') do |_root|
  assert(Standards.escape_command("name,%\n::error", property: true) == 'name%2C%25%0A%3A%3Aerror')
  assert(!Standards.markdown("<script>|[link]\n").include?('<script>'))
  Standards::DOCS.each_value do |reference|
    page, anchor = reference.split('#')
    document = File.read(File.join(__dir__, '..', '..', 'docs', 'developer', 'standards', "#{page}.md"))
    assert(document.lines.any? { |line| line.match?(/\A#+ /) && line.sub(/\A#+ /, '').strip.downcase == anchor }, "Missing docs anchor #{reference}")
  end
end

check('CLI exit codes, JSON artifact, summary and deterministic findings') do |root|
  directory = solution(root, 'a', ["modernflows/#{FLOW_ID}"])
  flow(directory, FLOW_ID, 'Invalid')
  changes = File.join(root, 'changes.json')
  write_data(changes, ['solutions/a/changed.yml'])
  report = File.join(root, 'report.json')
  summary = File.join(root, 'summary.md')
  %w[main release].each do |base|
    output, error, status = Open3.capture3(RbConfig.ruby, File.join(__dir__, 'validate.rb'),
      '--root', root, '--base', base, '--changed-files', changes, '--report', report, '--summary', summary)
    assert(status.exitstatus == (base == 'main' ? 1 : 0), error)
    assert(Standards.read_data(report)['solution'] == 'a')
    assert(File.read(summary).include?('[Docs](https://'))
    assert(output.include?("::#{base == 'main' ? 'error' : 'warning'}"))
  end
  _, _, status = Open3.capture3(RbConfig.ruby, File.join(__dir__, 'validate.rb'), '--base', 'release')
  assert(status.exitstatus == 2)
  assert(validate(root).first == validate(root).first)
end

check('trusted workflow structure, events and isolated candidate tests') do |_root|
  quality = Standards.read_data(File.join(__dir__, '..', '..', '.github', 'workflows', 'label-pull-request.yml'))
  events = quality['on'] || quality[true]
  assert(events.keys == ['pull_request_target'])
  assert(%w[labeled unlabeled edited synchronize].all? { |event| events['pull_request_target']['types'].include?(event) })
  assert(quality.dig('jobs', 'quality', 'name') == 'Power Platform standards')
  assert(quality.dig('jobs', 'quality', 'if') == 'always()')
  steps = quality.dig('jobs', 'validate', 'steps')
  checkouts = steps.select { |step| step['uses'] == 'actions/checkout@v4' }
  assert(checkouts.all? { |step| step['with']['persist-credentials'] == false })
  assert(checkouts.first['with']['ref'].include?('base.sha'))
  assert(checkouts.last['with']['ref'].include?('head.sha'))
  run = steps.find { |step| step['name'] == 'Validate resources with trusted rules' }['run']
  assert(run.include?('ruby trusted/scripts/standards/validate.rb') && run.include?('--root source'))
  assert(!steps.any? { |step| step.fetch('run', '').match?(/npm ci|gem install|bundle install/) })
  tests = Standards.read_data(File.join(__dir__, '..', '..', '.github', 'workflows', 'standards-tests.yml'))
  assert((tests['on'] || tests[true]).key?('pull_request'))
  assert(tests['permissions'] == { 'contents' => 'read' })
end

check('actual final gate script rejects failed/cancelled/missing dependencies') do |root|
  quality = Standards.read_data(File.join(__dir__, '..', '..', '.github', 'workflows', 'label-pull-request.yml'))
  script = quality.dig('jobs', 'quality', 'steps').first.fetch('run')
  [
    ['success', 'success', 'true', 0], ['success', 'skipped', 'false', 0],
    ['failure', 'skipped', 'true', 1], ['cancelled', 'skipped', 'false', 1],
    ['success', 'failure', 'true', 1], ['success', 'cancelled', 'true', 1],
    ['success', 'skipped', 'true', 1], ['success', 'success', 'false', 1],
    ['success', 'skipped', '', 1]
  ].each do |prepare, validation, dev, expected|
    env = { 'PREPARE_RESULT' => prepare, 'VALIDATE_RESULT' => validation, 'IS_DEV' => dev,
            'GITHUB_STEP_SUMMARY' => File.join(root, 'summary.md') }
    output, error, status = Open3.capture3(env, 'bash', '--noprofile', '--norc', '-eo', 'pipefail', '-c', script)
    assert(status.exitstatus == expected, "#{prepare}/#{validation}/#{dev}: #{output} #{error}")
  end
end

check('actual branch-labeling script recognizes current and legacy routes without network writes') do |root|
  quality = Standards.read_data(File.join(__dir__, '..', '..', '.github', 'workflows', 'label-pull-request.yml'))
  script = quality.dig('jobs', 'prepare', 'steps').first.fetch('run')
  [
    ['core/v1.0.0/spr-70', 'dev'], ['core/v1.0.0/release', 'dev'],
    ['change-viewer/v2.1.0/spr-1', 'dev'], ['core/spr-70', 'dev'],
    ['core/v1.0.0', 'dev'], ['docs/naming', 'docs'], ['project/standards', 'project'],
    ['unclassified-branch', nil]
  ].each do |branch, expected|
    label_file = File.join(root, 'label.txt')
    FileUtils.rm_f(label_file)
    env = { 'HEAD_BRANCH' => branch, 'GITHUB_REPOSITORY' => 'example/repo', 'PR_NUMBER' => '1',
            'TEST_LABEL_FILE' => label_file }
    stub = 'gh() { if [[ "$1" == "label" ]]; then printf "%s" "$3" > "$TEST_LABEL_FILE"; fi; };' + "\n"
    _, error, status = Open3.capture3(env, 'bash', '--noprofile', '--norc', '-eo', 'pipefail', '-c', stub + script)
    assert(status.success?, error)
    assert((File.exist?(label_file) ? File.read(label_file) : nil) == expected, branch)
  end
end

CASES.each do |name, block|
  Dir.mktmpdir('ppat-standards-') { |root| block.call(root) }
  puts "PASS #{name}"
end
puts "#{CASES.length} test groups passed."
