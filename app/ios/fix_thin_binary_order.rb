#!/usr/bin/env ruby
# Flutter + WidgetKit 확장 동시 빌드 시 "Thin Binary" 스크립트 페이즈와 확장 임베드
# Copy 페이즈 사이에 의존성 사이클이 생긴다. home_widget 문서 권고대로 "Thin Binary"
# 페이즈를 빌드 페이즈 맨 마지막으로 이동해 사이클을 해소한다.
require 'xcodeproj'

proj = Xcodeproj::Project.open('Runner.xcodeproj')
runner = proj.targets.find { |t| t.name == 'Runner' } or abort 'Runner not found'

thin = runner.build_phases.find do |ph|
  ph.respond_to?(:name) && ph.name == 'Thin Binary'
end
abort 'Thin Binary phase not found' unless thin

if runner.build_phases.last == thin
  puts '[skip] Thin Binary already last'
else
  runner.build_phases.delete(thin)
  runner.build_phases << thin
  proj.save
  puts '[ok] moved Thin Binary to the last build phase'
end

puts 'phases order:'
runner.build_phases.each_with_index do |ph, i|
  label = ph.respond_to?(:name) && ph.name ? ph.name : ph.isa
  puts "  #{i}: #{label}"
end
