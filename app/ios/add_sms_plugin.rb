#!/usr/bin/env ruby
# SmsComposerPlugin.swift 를 Runner 타깃(그룹+Sources 빌드 페이즈)에 추가한다. (idempotent)
require 'xcodeproj'

PROJECT = 'Runner.xcodeproj'
FILE = 'SmsComposerPlugin.swift'

proj = Xcodeproj::Project.open(PROJECT)
runner = proj.targets.find { |t| t.name == 'Runner' } or abort 'Runner target not found'

# 이미 추가돼 있으면 skip.
if runner.source_build_phase.files_references.any? { |r| r.path == FILE || (r.display_name == FILE) }
  puts "[skip] #{FILE} already in Runner sources"
  exit 0
end

# Runner 그룹에 파일 참조 추가(경로 Runner/SmsComposerPlugin.swift).
runner_group = proj.main_group.find_subpath('Runner', true)
ref = runner_group.files.find { |f| f.path == FILE }
ref ||= runner_group.new_reference(FILE)
runner.add_file_references([ref])

proj.save
puts "[ok] added #{FILE} to Runner target"
