class Recording < ActiveRecord::Base
  validates :url, :bus, presence: true

  default_scope { where(hidden: false) }
  default_scope { order('recordings.created_at DESC') }

  def self.nearest(line, id = nil)
    return where(bus: line).last if id.nil?
    where(id: id, bus: line).last || where(bus: line).last
  end

  def self.next(line, id)
    where(bus: line).where('created_at < ?', find(id).created_at).first
  end

  def self.prev(line, id)
    where(bus: line).where('created_at > ?', find(id).created_at).last
  end

  def self.exists_for_bus?(line)
    where(bus: line).exists?
  end
end
