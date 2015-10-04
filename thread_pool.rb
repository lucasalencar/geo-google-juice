class ThreadPool
  def initialize(max_threads)
    @max_threads = max_threads
    @threads = []
  end

  def add(thread)
    @threads << thread
  end

  def reached_max?
    @threads.size >= @max_threads
  end

  def hold
    @threads.each { |thr| thr.join }
    @threads.clear
  end
end
