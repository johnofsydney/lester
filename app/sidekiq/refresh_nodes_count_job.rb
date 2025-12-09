require 'sidekiq-scheduler'

class RefreshNodesCountJob
  include Sidekiq::Job
  # There are ~280k people and ~50k groups,
  # Running 2000 jobs per 5 mins would take ~80 mins to complete a full cycle

  QUANTITY = 2000

  def perform
    people_ids = people_to_refresh.pluck(:id)
    push_bulk_jobs('Person', people_ids) if people_ids.any?

    group_ids = groups_to_refresh.pluck(:id)
    push_bulk_jobs('Group', group_ids) if group_ids.any?

    # Re-enqueue itself until fully done
    self.class.perform_in(5.minutes) if more_remaining?
  end

  def push_bulk_jobs(klass_name, ids, slice_size: 500)
    args = ids.map { |id| [klass_name, id] }
    pushed = 0
    args.each_slice(slice_size) do |chunk|
      begin
        Sidekiq::Client.push_bulk('class' => NodeCountJob, 'args' => chunk)
        pushed += chunk.size
        Rails.logger.info "RefreshNodesCountJob: pushed #{people_ids.size} people, #{group_ids.size} groups; rescheduled=#{more_remaining?}"
      rescue => e
        Rails.logger.warn "RefreshNodesCountJob: push_bulk failed for #{klass_name} chunk (#{e.class}): falling back to individual enqueues"
        chunk.each do |(k, id)|
          begin
            NodeCountJob.perform_async(k, id)
            pushed += 1
          rescue => inner_e
            Rails.logger.error "RefreshNodesCountJob enqueue error for #{k} #{id}: #{inner_e.class} #{inner_e.message}"
          end
        end
      end
    end

    Rails.logger.info "RefreshNodesCountJob: bulk pushed #{pushed} #{klass_name} jobs"
  end

  def people_to_refresh
    Person.nodes_count_expired.limit(QUANTITY)
  end

  def groups_to_refresh
    Group.nodes_count_expired.limit(QUANTITY)
  end

  def more_remaining?
    Person.nodes_count_expired.offset(QUANTITY).exists? || Group.nodes_count_expired.offset(QUANTITY).exists?
  end
end

# Sidekiq::Client.push_bulk expects to be called like this:
# Sidekiq::Client.push_bulk(
#   'class' => MyWorker,
#   'args' => [[arg1_job1, arg2_job1], [arg1_job2, arg2_job2], ...]
# )

# In our case above this will be:
# Sidekiq::Client.push_bulk(
#   'class' => NodeCountJob,
#   'args' => [['Person', id1], ['Person', id2], ...]
# )
