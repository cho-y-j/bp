#!/usr/bin/env ruby
# 작업온 iOS 홈 위젯(WidgetKit) 확장 타깃을 프로젝트에 추가한다.
# - 배포 타깃 15.0 통일(Podfile 15.0 정합)
# - Runner + WorkonWidgetExtension 에 App Group(group.kr.workon) 부여
# - Embed App Extensions 단계 추가
require 'xcodeproj'

PROJECT = 'Runner.xcodeproj'
TARGET_NAME = 'WorkonWidgetExtension'
BUNDLE_ID = 'kr.workon.workon.WorkonWidget'
GROUP_ID = 'group.kr.workon'
TEAM = 'F9MRNA9WLY'
DEPLOY = '15.0'

proj = Xcodeproj::Project.open(PROJECT)

# 이미 추가돼 있으면 중복 생성 방지 (idempotent).
if proj.targets.any? { |t| t.name == TARGET_NAME }
  puts "[skip] #{TARGET_NAME} already exists"
  exit 0
end

runner = proj.targets.find { |t| t.name == 'Runner' } or abort 'Runner target not found'

# 1) 전체 배포 타깃 15.0 통일 (project-level + 모든 타깃).
(proj.build_configurations + proj.targets.flat_map(&:build_configurations)).each do |cfg|
  if cfg.build_settings.key?('IPHONEOS_DEPLOYMENT_TARGET')
    cfg.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOY
  end
end

# 2) Runner 에 App Group 엔타이틀먼트 연결.
runner.build_configurations.each do |cfg|
  cfg.build_settings['CODE_SIGN_ENTITLEMENTS'] = 'Runner/Runner.entitlements'
end

# 3) 위젯 확장 타깃 생성.
widget = proj.new_target(:app_extension, TARGET_NAME, :ios, DEPLOY)

# 소스 그룹 + 파일 참조.
grp = proj.main_group.new_group('WorkonWidget', 'WorkonWidget')
swift_files = ['WorkonWidget.swift', 'WorkonWidgetBundle.swift']
swift_files.each do |f|
  ref = grp.new_reference(f)
  widget.source_build_phase.add_file_reference(ref)
end
# Info.plist / entitlements 는 그룹에 노출만(컴파일 X).
grp.new_reference('Info.plist')
grp.new_reference('WorkonWidget.entitlements')

# 4) 시스템 프레임워크 링크.
widget.add_system_framework('WidgetKit')
widget.add_system_framework('SwiftUI')

# 5) 빌드 설정.
widget.build_configurations.each do |cfg|
  bs = cfg.build_settings
  bs['PRODUCT_BUNDLE_IDENTIFIER'] = BUNDLE_ID
  bs['PRODUCT_NAME'] = '$(TARGET_NAME)'
  bs['INFOPLIST_FILE'] = 'WorkonWidget/Info.plist'
  bs['CODE_SIGN_ENTITLEMENTS'] = 'WorkonWidget/WorkonWidget.entitlements'
  bs['CODE_SIGN_STYLE'] = 'Automatic'
  bs['DEVELOPMENT_TEAM'] = TEAM
  bs['SWIFT_VERSION'] = '5.0'
  bs['IPHONEOS_DEPLOYMENT_TARGET'] = DEPLOY
  bs['TARGETED_DEVICE_FAMILY'] = '1,2'
  bs['SKIP_INSTALL'] = 'YES'
  bs['GENERATE_INFOPLIST_FILE'] = 'NO'
  bs['CURRENT_PROJECT_VERSION'] = '1'
  bs['MARKETING_VERSION'] = '1.0.0'
  bs['SWIFT_EMIT_LOC_STRINGS'] = 'YES'
  bs['ENABLE_USER_SCRIPT_SANDBOXING'] = 'YES'
end

# 6) Runner 가 위젯을 의존 + 임베드.
runner.add_dependency(widget)
embed = runner.new_copy_files_build_phase('Embed Foundation Extensions')
embed.symbol_dst_subfolder_spec = :plug_ins
embed.dst_path = ''
bf = embed.add_file_reference(widget.product_reference)
bf.settings = { 'ATTRIBUTES' => ['RemoveHeadersOnCopy'] }

proj.save
puts "[ok] added #{TARGET_NAME} (bundle #{BUNDLE_ID}, deploy #{DEPLOY}, group #{GROUP_ID}, team #{TEAM})"
