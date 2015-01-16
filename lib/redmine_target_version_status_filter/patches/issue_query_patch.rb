require_dependency 'query'
if ActiveSupport::Dependencies::search_for_file('issue_query')
  require_dependency 'issue_query'
end

module RedmineTargetVersionStatusFilter
  module Patches
    module IssueQueryPatch
      def self.included(base) # :nodoc:
        base.send(:include, InstanceMethods)

        # Same as typing in the class
        base.class_eval do
          unloadable # Send unloadable so it will not be unloaded in development
          alias_method_chain :statement, :target_version_status
          alias_method :available_filters_without_target_version_status, :available_filters
          alias_method :available_filters, :available_filters_with_target_version_status
        end
      end

      module InstanceMethods

        def statement_with_target_version_status
            filter  = filters.delete 'target_version_status'
            clauses = statement_without_target_version_status || ""
            if filter
              filters.merge!( 'target_version_status' => filter )

              op = operator_for('target_version_status')

              project_versions = Version.where(:project_id => project_id)
              apply_filter = true
              case op
              when '=', '!'
                ids_list = project_versions.where(:status => value_for('target_version_status').clone).pluck(:id).push(0)
              when '!*'
                ids_list = []
                apply_filter = false
                clauses << " AND " unless clauses.empty?
                clauses << "( #{Issue.table_name}.fixed_version_id IS NULL ) "
              else
                ids_list = project_versions.pluck(:id).push(0)
              end
              ids_list << 0
              if apply_filter
                compare   = op.eql?('!') ? 'NOT IN' : 'IN'
                ids_list = ids_list.join(', ')

                clauses << " AND " unless clauses.empty?
                clauses << "( #{Issue.table_name}.fixed_version_id #{compare} (#{ids_list}) ) "
              end
            end
            clauses
        end

        def available_filters_with_target_version_status
          unless @available_filters
            available_filters_without_target_version_status.merge!({
              'target_version_status' => {
                :name   => l(:target_version_status),
                :type   => :list_optional,
                :order  => 7,
                :values => Version::VERSION_STATUSES.collect{ |t| [t, t] }
              }
            })
          end
          @available_filters
        end
      end
    end
  end
end

base = ActiveSupport::Dependencies::search_for_file('issue_query') ? IssueQuery : Query
unless base.included_modules.include?(RedmineTargetVersionStatusFilter::Patches::IssueQueryPatch)
  base.send(:include, RedmineTargetVersionStatusFilter::Patches::IssueQueryPatch)
end
