require 'helper'

class TestLogger < Test::Unit::TestCase
  context "with logger with mocked sender" do
    setup do
      Socket.stubs(:gethostname).returns('stubbed_hostname')
      @logger = GELF::Logger.new
      @sender = mock
      @logger.instance_variable_set('@sender', @sender)
    end

    should "respond to #close" do
      assert @logger.respond_to?(:close)
    end

    context "#add" do

      # logger.add(Logger::INFO, 'Message')
      should "implement add method with level and message from parameters" do
        @logger.expects(:notify_with_level!).with do |level, hash|
          level == GELF::INFO &&
          hash['short_message'] == 'Message' &&
          hash['facility'].nil?
        end
        @logger.add(GELF::INFO, nil, 'Message')
      end

      # logger.add(Logger::INFO, RuntimeError.new('Boom!'))
      should "implement add method with level and exception from parameters" do
        @logger.expects(:notify_with_level!).with do |level, hash|
          level == GELF::INFO &&
          hash['short_message'] == 'RuntimeError: Boom!' &&
          hash['full_message'] =~ /^Backtrace/ &&
          hash['facility'].nil?
        end
        @logger.add(GELF::INFO, nil, RuntimeError.new('Boom!'))
      end

      # logger.add(Logger::INFO) { 'Message' }
      should "implement add method with level from parameter, message from blocks" do
        @logger.expects(:notify_with_level!).with do |level, hash|
          level == GELF::INFO &&
          hash['short_message'] == 'Message' &&
          hash['facility'].nil?
        end
        @logger.add(GELF::INFO, nil, nil) { 'Message' }
      end

      # logger.add(Logger::INFO) { RuntimeError.new('Boom!') }
      should "implement add method with level from parameter, exception from block" do
        @logger.expects(:notify_with_level!).with do |level, hash|
          level == GELF::INFO &&
          hash['short_message'] == 'RuntimeError: Boom!' &&
          hash['full_message'] =~ /^Backtrace/ &&
          hash['facility'].nil?
        end
        @logger.add(GELF::INFO, nil, nil) { RuntimeError.new('Boom!') }
      end

      # logger.add(Logger::INFO, 'Message', 'Facility')
      should "implement add method with level, message and facility from parameters" do
        @logger.expects(:notify_with_level!).with do |level, hash|
          level == GELF::INFO &&
          hash['short_message'] == 'Message' &&
          hash['facility'] == 'Facility'
        end
        @logger.add(GELF::INFO, 'Message', 'Facility')
      end

      # logger.add(Logger::INFO, 'Message', nil)
      should "use facility from initialization if facility is nil" do
        logger = GELF::Logger.new('localhost', 12202, 'WAN', :facility => 'foo-bar')
        logger.expects(:notify_with_level!).with do |level, hash|
          level == GELF::INFO &&
          hash['short_message'] == 'Message' &&
          hash['facility'] == 'foo-bar'
        end
        logger.add(GELF::INFO, 'Message', nil)
      end

      # logger.add(Logger::INFO, 'Message', nil)
      should "leave facility empty if facility is nil" do
        @logger.expects(:notify_with_level!).with do |level, hash|
          level == GELF::INFO &&
          hash['short_message'] == 'Message' &&
            hash['facility'].nil?
        end
        @logger.add(GELF::INFO, 'Message', nil)
      end

      # logger.add(Logger::INFO, RuntimeError.new('Boom!'), 'Facility')
      should "implement add method with level, exception and facility from parameters" do
        @logger.expects(:notify_with_level!).with do |level, hash|
          level == GELF::INFO &&
          hash['short_message'] == 'RuntimeError: Boom!' &&
          hash['full_message'] =~ /^Backtrace/ &&
          hash['facility'] == 'Facility'
        end
        @logger.add(GELF::INFO, RuntimeError.new('Boom!'), 'Facility')
      end

      # logger.add(Logger::INFO, nil, 'Facility') { 'Message' }
      should "implement add method with level and facility from parameters, message from block" do
        @logger.expects(:notify_with_level!).with do |level, hash|
          level == GELF::INFO &&
          hash['short_message'] == 'Message' &&
          hash['facility'] == 'Facility'
        end
        @logger.add(GELF::INFO, nil, 'Facility') { 'Message' }
      end

      # logger.add(Logger::INFO, nil, 'Facility') { RuntimeError.new('Boom!') }
      should "implement add method with level and facility from parameters, exception from block" do
        @logger.expects(:notify_with_level!).with do |level, hash|
          level == GELF::INFO &&
          hash['short_message'] == 'RuntimeError: Boom!' &&
          hash['full_message'] =~ /^Backtrace/ &&
          hash['facility'] == 'Facility'
        end
        @logger.add(GELF::INFO, nil, 'Facility') { RuntimeError.new('Boom!') }
      end

      # logger.add(Logger::INFO, { :short_message => "Some message" })
      should "implement add method with level and message from hash" do
        @logger.expects(:notify_with_level!).with do |level, hash|
          level == GELF::INFO &&
          hash['short_message'] == 'Some message' &&
          hash['facility'].nil?
        end
        @logger.add(GELF::INFO, { :short_message => "Some message" })
      end

      # logger.add(Logger::INFO, { :short_message => "Some message", :_foo => "bar", "_zomg" => "wat" })
      should "implement add method with level and message from hash and some additional fields" do
        @logger.expects(:notify_with_level!).with do |level, hash|
          level == GELF::INFO &&
          hash['short_message'] == 'Some message' &&
          hash['facility'].nil? &&
          hash['_foo'] == 'bar' &&
          hash['_zomg'] == 'wat'
        end
        @logger.add(GELF::INFO, { :short_message => "Some message", :_foo => "bar", "_zomg" => "wat"})
      end

      # logger.add(Logger::INFO, { :short_message => "Some message", :_foo => "bar", "_zomg" => "wat" }, 'somefac')
      should "implement add method with level and message from hash, facility from parameters and some additional fields" do
        @logger.expects(:notify_with_level!).with do |level, hash|
          level == GELF::INFO &&
          hash['short_message'] == 'Some message' &&
          hash['facility'] == 'somefac' &&
          hash['_foo'] == 'bar' &&
          hash['_zomg'] == 'wat'
        end
        @logger.add(GELF::INFO, { :short_message => "Some message", :_foo => "bar", "_zomg" => "wat"}, "somefac")
      end

      should 'implement add method with level and ignore zero-length message strings' do
        @logger.expects(:notify_with_level!).never
        @logger.add(GELF::INFO, '')
      end

      should 'implement add method with level and ignore hash without short_message key' do
        @logger.expects(:notify_with_level!).never
        @logger.add(GELF::INFO, { :message => 'Some message' })
      end

      should 'implement add method with level and ignore hash with zero-length short_message entry' do
        @logger.expects(:notify_with_level!).never
        @logger.add(GELF::INFO, { :short_message => '' })
      end

       # logger.add(Logger::INFO) { 'Message' }
       should "implement add method with level and message from block with rails formatter" do
        @logger.formatter = proc do |severity, datetime, progname, msg|
          "#{severity} - #{datetime.strftime("%Y") } - [#{progname}]: #{msg}"
        end
        @logger.expects(:notify_with_level!).with do |level, hash|
          level == GELF::INFO &&
          hash['short_message'] == "1 - #{Time.now.strftime("%Y")} - []: Message"
        end
        @logger.add(GELF::INFO) { 'Message' }
      end

    end

    GELF::Levels.constants.each do |const|
      # logger.error "Argument #{ @foo } mismatch."
      should "call add with level #{const} from method name, message from parameter" do
        @logger.expects(:notify_with_level!).with do |level, hash|
          level == GELF.const_get(const) &&
          hash['short_message'] == 'message' &&
            hash['facility'].nil?
        end
        @logger.__send__(const.downcase, 'message')
      end

      # logger.fatal { "Argument 'foo' not given." }
      should "call add with level #{const} from method name, message from block" do
        @logger.expects(:notify_with_level!).with do |level, hash|
          level == GELF.const_get(const) &&
          hash['short_message'] == 'message' &&
          hash['facility'].nil?
        end
        @logger.__send__(const.downcase) { 'message' }
      end

      # logger.info('initialize') { "Initializing..." }
      should "call add with level #{const} from method name, facility from parameter, message from block" do
        @logger.expects(:notify_with_level!).with do |level, hash|
          level == GELF.const_get(const) &&
          hash['short_message'] == 'message' &&
          hash['facility'] == 'facility'
        end
        @logger.__send__(const.downcase, 'facility') { 'message' }
      end

      should "respond to #{const.downcase}?" do
        @logger.level = GELF.const_get(const) - 1
        assert @logger.__send__(const.to_s.downcase + '?')
        @logger.level = GELF.const_get(const)
        assert @logger.__send__(const.to_s.downcase + '?')
        @logger.level = GELF.const_get(const) + 1
        assert !@logger.__send__(const.to_s.downcase + '?')
      end
    end

    should "support Logger#<<" do
      @logger.expects(:notify_with_level!).with do |level, hash|
        level == GELF::UNKNOWN &&
        hash['short_message'] == "Message"
      end
      @logger << "Message"
    end

    should "have formatter attribute" do
      @logger.formatter
    end

    context "close" do
      should "close socket" do
        @sender.expects(:close).once
        @logger.close
      end
    end
  end
end
