require 'simplecov'
SimpleCov.start
ENV["RAILS_ENV"] ||= 'test'
require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'database_cleaner'
require 'capybara/rspec'
require 'wisper/rspec/stub_wisper_publisher'
require 'rspec/cells'
require 'lib/tasks/orientdb_task'
# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f }

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  #

  config.include JsonSpec::Helpers
  config.filter_run_excluding broken: :true

  config.pattern = FileList[config.pattern].exclude('migration')

  config.before(:suite) do
    raise "You don't seem to be using a test url: #{Oriented.configuration.url}" if (Oriented.configuration.url =~ /test/).nil?    
    sa = Java::ComOrientechnologiesOrientClientRemote::OServerAdmin.new(Oriented.configuration.url).connect(Oriented.configuration.username, Oriented.configuration.password)
    unless sa.existsDatabase('plocal')
      sa.createDatabase("graph", "plocal");
      OrientDBTask.new.create_schema  
    end
    sa.close()


    DatabaseCleaner.strategy = :truncation
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:all) do
    Oriented.graph.auto_start_tx = false
    Oriented.graph.commit

    ecmd = OrientDB::SQLCommand.new("delete from E")
    Oriented.graph.command(ecmd).execute
    vcmd = OrientDB::SQLCommand.new("delete from V")
    Oriented.graph.command(vcmd).execute

    Oriented.graph.auto_start_tx= true
    Oriented.graph.commit
  end

  config.before(:each) do

    Account.delete_all
    FactoryGirl.factories.clear
    FactoryGirl.traits.clear
    FactoryGirl.sequences.clear
    FactoryGirl.find_definitions
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean

    Oriented.graph.auto_start_tx = false
    Oriented.graph.commit
    ecmd = OrientDB::SQLCommand.new("delete from E")
    Oriented.graph.command(ecmd).execute
    vcmd = OrientDB::SQLCommand.new("delete from V")
    Oriented.graph.command(vcmd).execute

    Oriented.graph.auto_start_tx= true
    Oriented.graph.commit

  end

  config.include Devise::TestHelpers, :type => :controller

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  # config.use_transactional_fixtures = true

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"
  config.extend Devise::TestHelpers, type: :controller

  OmniAuth.config.test_mode = true
  OmniAuth.config.add_mock(:kyck, {
    "provider" => "kyck",
    "uid" => UUIDTools::UUID.random_create,
    "info" => {
      "email" => "fred@flintstone.com",
      "first_name" => "Fred",
      "last_name" => "Flintstone"
    },
    "extra" => {
      "raw_info" => {
        "admin" => "false"
      }
    },
    "credentials" => {"token" => "123456789"}
  })
end
