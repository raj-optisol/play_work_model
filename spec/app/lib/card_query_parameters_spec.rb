# encoding: UTF-8
require 'spec_helper'

describe CardQueryParameters do
  describe "#sql" do
    context "when querying for a user" do
      let(:params) { { user_conditions: { "last_name"=>"Goodrich", "first_name"=>"Abby"}, card_conditions: {} } }
      subject { described_class.new(params) }

      it "creates the right sql" do
        assert_equal("select from card  where first_name = 'abby' AND last_name = 'goodrich'",
          subject.sql)
      end

      context "with birthdate" do
        let(:params) { { user_conditions: { "last_name"=>"Goodrich", "first_name"=>"Abby", "birthdate"=>'2004-08-03'}, card_conditions: {} } }
        subject { described_class.new(params) }

        it "creates the right sql" do
          sql = "select from card  where birthdate = date('2004-08-03', 'yyyy-MM-dd') AND first_name = 'abby' AND last_name = 'goodrich'"
          assert_equal(sql, subject.sql)
        end
      end
    end

    context "when querying for a organization" do
      let(:params) { { organization_conditions: { 'kyck_id' => '1235'}, card_conditions: {} } }
      subject { described_class.new(params) }

      it "creates the right sql" do
        sql = "select from (select expand(in('Card__carded_for')) from Organization where kyck_id = '1235') "
        assert_equal(sql, subject.sql)
      end
    end

    context "when querying for a sanction" do
      let(:params) { { sanction_conditions: { 'kyck_id' => '1235'}, card_conditions: {} } }
      subject { described_class.new(params) }

      it "creates the right sql" do
        sql = "select from (select expand(in('Card__carded_for')) from (traverse in from (select from (traverse out_sanctions from #13:0) where kyck_id = '1235'))) "
        assert_equal(sql, subject.sql)
      end

      context "that isn't uscs" do

        it "creates the right sql" do
          subject.sanctioning_body_id = "#13:5"
          sql = "select from (select expand(in('Card__carded_for')) from (traverse in from (select from (traverse out_sanctions from #13:5) where kyck_id = '1235'))) "
          assert_equal(sql, subject.sql)
        end
      end
    end

    context "when querying for a team" do
      let(:params) { { team_conditions: { 'kyck_id' => '1235'}, card_conditions: {} } }
      subject { described_class.new(params) }

      it "creates the right sql" do
        sql = "select from (select expand(in('Card__carded_user')) from (select expand(distinct(out))  from (traverse out_Team__rosters, in_staff_for, in_plays_for from (select from Team where kyck_id = '1235')) where @class IN ['staff_for', 'plays_for'])) "
        assert_equal(sql, subject.sql)
      end
    end
  end
end
