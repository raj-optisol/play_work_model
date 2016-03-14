require 'spec_helper'
require_relative '../../app/helpers/application_helper'
require_relative '../../app/models/user'

describe QueryHelper do

  describe "default query options" do
    subject do
      Object.new.extend(ApplicationHelper)
      Object.new.extend(QueryHelper)
    end

    context "when params not specified" do
      it "sets the default query options" do
        res = subject.default_query_options({})
        res[:limit].should == 25
      end
    end

    context "when params are specified" do
      it "sets the specified options" do
        res = subject.default_query_options(params={orderby: 'something_else', dir: 'asc', per_page: 10})
        res[:limit].should == 10
        res[:order].should == "something_else"
        res[:order_dir].should == 'asc'
      end
    end
  end
end
