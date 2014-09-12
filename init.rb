require 'redmine'
require 'redmine_target_version_status_filter/patches/issue_query_patch'

Redmine::Plugin.register :redmine_target_version_status_filter do
  name 'Redmine - Target Version Status Filter plugin'
  author 'Gabriel Croitoru'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  url 'http://example.com/path/to/plugin'
  author_url 'http://example.com/about'
end

